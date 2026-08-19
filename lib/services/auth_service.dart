import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/injection.dart';
import '../core/security/e2ee_service.dart';
import '../features/auth/domain/usecases/login_use_case.dart';
import '../features/auth/domain/usecases/signup_use_case.dart';
import '../features/auth/domain/usecases/sign_out_use_case.dart';
import 'log_service.dart';

enum LoginResult { success, requires2FA, failure }

class AuthService with ChangeNotifier {
  final sb.SupabaseClient _supabaseClient = sl<sb.SupabaseClient>();

  sb.User? _currentUser;
  sb.User? get currentUser => _currentUser;

  bool _requires2FA = false;
  bool get requires2FA => _requires2FA;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<sb.AuthState>? _authStateSubscription;

  final LoginUseCase _loginUseCase = sl<LoginUseCase>();
  final SignupUseCase _signupUseCase = sl<SignupUseCase>();
  final SignOutUseCase _signOutUseCase = sl<SignOutUseCase>();

  bool _hasAcceptedTerms = false;
  bool get hasAcceptedTerms => _hasAcceptedTerms;

  AuthService() {
    // Set initial user
    _currentUser = _supabaseClient.auth.currentUser;
    LogService.auth("AuthService initialized. Current user: ${_currentUser?.email ?? 'Guest'}");
    if (_currentUser != null) {
      sl<E2EEService>().initializeKeys();
      checkTermsAccepted();
    }

    // Listen to Supabase auth events
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      final wasSignedOut = _currentUser == null;
      _currentUser = data.session?.user;
      
      if (_currentUser != null && wasSignedOut) {
        sl<E2EEService>().initializeKeys();
        checkTermsAccepted();
      }
      
      notifyListeners();
    });
  }

  Future<void> checkTermsAccepted() async {
    if (_currentUser == null) {
      _hasAcceptedTerms = false;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasAcceptedTerms = prefs.getBool('terms_accepted_${_currentUser!.id}') ?? false;
    } catch (_) {
      _hasAcceptedTerms = false;
    }
    notifyListeners();
  }

  Future<void> markTermsAccepted() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted_${_currentUser!.id}', true);
      _hasAcceptedTerms = true;
    } catch (_) {}
    notifyListeners();
  }

  bool _isSigningOut = false;
  bool get isSigningOut => _isSigningOut;
  bool get isUserSignedIn => _currentUser != null && !_isSigningOut;
  String get currentUid => _currentUser?.id ?? '';
  bool get isEmailVerified => _currentUser?.emailConfirmedAt != null;

  Future<LoginResult> handleLogin(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _requires2FA = false;
    notifyListeners();
    LogService.auth("Attempting login for: $emailOrUsername");

    String emailToUse = emailOrUsername.trim();
    if (!emailToUse.contains('@')) {
      // It's a username!
      try {
        final profileRes = await _supabaseClient
            .from('profiles')
            .select('email')
            .eq('username', emailToUse.toLowerCase())
            .maybeSingle();
        if (profileRes != null && profileRes['email'] != null) {
          emailToUse = profileRes['email'] as String;
        } else {
          _isLoading = false;
          _errorMessage = "Username not found. Please try again or sign up.";
          notifyListeners();
          return LoginResult.failure;
        }
      } catch (e) {
        debugPrint("Username mapping error: $e");
        _isLoading = false;
        _errorMessage = "Unable to resolve username. Please use your email.";
        notifyListeners();
        return LoginResult.failure;
      }
    }

    final result = await _loginUseCase(emailToUse, password);
    
    return result.fold(
      (failure) {
        _isLoading = false;
        String mappedMsg = failure.message;
        if (mappedMsg.toLowerCase().contains("invalid login credentials") || 
            mappedMsg.toLowerCase().contains("invalid_credentials")) {
          mappedMsg = "Invalid email/username or password. Please try again.";
        }
        _errorMessage = mappedMsg;
        notifyListeners();
        return LoginResult.failure;
      },
      (userEntity) async {
        try {
          final res = _supabaseClient.auth.mfa.getAuthenticatorAssuranceLevel();
          if (res.nextLevel == sb.AuthenticatorAssuranceLevels.aal2 && res.currentLevel == sb.AuthenticatorAssuranceLevels.aal1) {
            _requires2FA = true;
            _isLoading = false;
            notifyListeners();
            return LoginResult.requires2FA;
          }
        } catch (e) {
          debugPrint('Error checking AAL: $e');
        }
        
        _currentUser = _supabaseClient.auth.currentUser;
        LogService.auth("Login successful for user: ${_currentUser?.email} (ID: ${_currentUser?.id})");
        await markTermsAccepted();
        _isLoading = false;
        notifyListeners();
        // Log analytics login
        try {
          FirebaseAnalytics.instance.logLogin(loginMethod: 'email_or_username');
        } catch (e) {
          debugPrint('Error logging analytics login: $e');
        }
        return LoginResult.success;
      },
    );
  }

  Future<sb.AuthMFAEnrollResponse?> enrollMfa() async {
    try {
      final response = await _supabaseClient.auth.mfa.enroll(factorType: sb.FactorType.totp);
      return response;
    } catch (e) {
      debugPrint('Error enrolling MFA: $e');
      return null;
    }
  }

  Future<bool> verifyMfa(String factorId, String code) async {
    try {
      final challenge = await _supabaseClient.auth.mfa.challenge(factorId: factorId);
      await _supabaseClient.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );
      _requires2FA = false;
      _currentUser = _supabaseClient.auth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Invalid 2FA code.';
      notifyListeners();
      debugPrint('Error verifying MFA: $e');
      return false;
    }
  }

  Future<bool> unenrollMfa(String factorId) async {
    try {
      await _supabaseClient.auth.mfa.unenroll(factorId);
      return true;
    } catch (e) {
      debugPrint('Error unenrolling MFA: $e');
      return false;
    }
  }

  Future<sb.Factor?> getEnrolledFactor() async {
    try {
      final factors = await _supabaseClient.auth.mfa.listFactors();
      if (factors.all.isNotEmpty) {
        final verified = factors.all.where((f) => f.status == sb.FactorStatus.verified).toList();
        if (verified.isNotEmpty) return verified.first;
      }
    } catch (e) {
      debugPrint('Error listing MFA factors: $e');
    }
    return null;
  }

  Future<bool> handleSignup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String birthdate,
    String? username,
    String? division,
    String? city,
    String? village,
    String? zip,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _signupUseCase(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      gender: gender,
      birthdate: birthdate,
      username: username,
      division: division,
      city: city,
      village: village,
      zip: zip,
    );

    return result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (success) async {
        _isLoading = false;
        _currentUser = _supabaseClient.auth.currentUser;
        _hasAcceptedTerms = false;
        if (_currentUser != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('terms_accepted_${_currentUser!.id}', false);
          } catch (_) {}
        }
        notifyListeners();
        // Log analytics signup
        try {
          FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
        } catch (e) {
          debugPrint('Error logging analytics signup: $e');
        }
        return true;
      },
    );
  }

  Future<bool> isUsernameTaken(String username) async {
    if (username.trim().isEmpty) return false;
    try {
      final res = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint("isUsernameTaken error: $e");
      // Fallback/Mock behavior if database fails
      return ["admin", "test", "pigeon", "system"].contains(username.trim().toLowerCase());
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyResetOTP(String email, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: sb.OtpType.recovery,
      );
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseClient.auth.updateUser(
        sb.UserAttributes(password: newPassword.trim()),
      );
      await _supabaseClient.auth.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignout() async {
    _isSigningOut = true;
    notifyListeners();
    LogService.auth("Signing out current user: ${_currentUser?.email}");

    try {
      final result = await _signOutUseCase();
      result.fold(
        (failure) {
          _isSigningOut = false;
          _errorMessage = failure.message;
          notifyListeners();
        },
        (_) {
          LogService.auth("Sign out successful. Cleared session keys.");
          sl<E2EEService>().clearKeys();
          _currentUser = null;
          _isSigningOut = false;
          notifyListeners();
        },
      );
    } catch (e) {
      LogService.error("Sign out failed: $e", tag: "AUTH");
      _isSigningOut = false;
      _currentUser = null;
      notifyListeners();
    }
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> resendVerificationEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseClient.auth.resend(
        type: sb.OtpType.signup,
        email: email.trim(),
        emailRedirectTo: 'io.supabase.dak://login-callback',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
