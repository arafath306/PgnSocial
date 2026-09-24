import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saved_account.dart';
import '../models/profile.dart';
import '../services/log_service.dart';

class AccountSwitcherService with ChangeNotifier {
  static const String _kStorageKey = 'multi_saved_accounts_v1';
  final SupabaseClient _supabase = Supabase.instance.client;

  List<SavedAccount> _savedAccounts = [];
  List<SavedAccount> get savedAccounts => List.unmodifiable(_savedAccounts);

  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// Currently active account from saved accounts (if any)
  SavedAccount? get currentAccount {
    final uid = currentUserId;
    if (uid.isEmpty) return null;
    final index = _savedAccounts.indexWhere((a) => a.userId == uid);
    return index != -1 ? _savedAccounts[index] : null;
  }

  /// All saved accounts other than the currently active one
  List<SavedAccount> get otherAccounts {
    final uid = currentUserId;
    return _savedAccounts.where((a) => a.userId != uid).toList();
  }

  /// The primary second account (if exists)
  SavedAccount? get secondAccount => otherAccounts.isNotEmpty ? otherAccounts.first : null;

  Future<void> init() async {
    await _loadAccounts();
    _syncCurrentSessionWithSaved();

    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.userUpdated) {
        _syncCurrentSessionWithSaved();
      }
    });
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _savedAccounts = list
            .map((item) => SavedAccount.fromJson(item as Map<String, dynamic>))
            .where((acc) => acc.userId.isNotEmpty && acc.refreshToken.isNotEmpty)
            .toList();
        notifyListeners();
      }
    } catch (e) {
      LogService.error('Error loading saved accounts: $e', tag: 'ACCOUNT_SWITCHER');
    }
  }

  Future<void> _persistAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_savedAccounts.map((a) => a.toJson()).toList());
      await prefs.setString(_kStorageKey, raw);
    } catch (e) {
      LogService.error('Error persisting saved accounts: $e', tag: 'ACCOUNT_SWITCHER');
    }
  }

  void _syncCurrentSessionWithSaved() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    final refreshToken = session?.refreshToken;

    if (user != null && refreshToken != null && refreshToken.isNotEmpty) {
      final index = _savedAccounts.indexWhere((a) => a.userId == user.id);
      if (index != -1) {
        final existing = _savedAccounts[index];
        _savedAccounts[index] = existing.copyWith(
          refreshToken: refreshToken,
          email: user.email ?? existing.email,
          lastActive: DateTime.now(),
        );
      } else {
        // Add new entry for current user
        _savedAccounts.add(
          SavedAccount(
            userId: user.id,
            email: user.email ?? '',
            username: (user.userMetadata?['username'] as String?) ?? 'user',
            fullName: (user.userMetadata?['full_name'] as String?) ?? 'User',
            avatarUrl: user.userMetadata?['avatar_url'] as String?,
            refreshToken: refreshToken,
            lastActive: DateTime.now(),
          ),
        );
      }
      _persistAccounts();
      notifyListeners();
    }
  }

  /// Call this when current profile is loaded or updated to keep info in sync
  void syncProfile(Profile? profile) {
    if (profile == null) return;
    final session = _supabase.auth.currentSession;
    final refreshToken = session?.refreshToken ?? '';

    final index = _savedAccounts.indexWhere((a) => a.userId == profile.id);
    if (index != -1) {
      _savedAccounts[index] = _savedAccounts[index].copyWith(
        username: profile.username,
        fullName: profile.fullName,
        avatarUrl: profile.avatarUrl,
        isVerified: profile.isVerified,
        badgeType: profile.badgeType,
        refreshToken: refreshToken.isNotEmpty ? refreshToken : null,
        lastActive: DateTime.now(),
      );
    } else if (refreshToken.isNotEmpty) {
      _savedAccounts.add(
        SavedAccount(
          userId: profile.id,
          email: _supabase.auth.currentUser?.email ?? '',
          username: profile.username,
          fullName: profile.fullName,
          avatarUrl: profile.avatarUrl,
          refreshToken: refreshToken,
          isVerified: profile.isVerified,
          badgeType: profile.badgeType,
          lastActive: DateTime.now(),
        ),
      );
    }
    _persistAccounts();
    notifyListeners();
  }

  /// Switch actively logged in account using saved refresh token
  Future<bool> switchToAccount(BuildContext context, SavedAccount targetAccount) async {
    if (_isSwitching) return false;
    if (targetAccount.userId == currentUserId) return true;

    _isSwitching = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.setSession(targetAccount.refreshToken);
      final newSession = response.session;

      if (newSession != null) {
        // Update target account with newly generated refresh token
        final index = _savedAccounts.indexWhere((a) => a.userId == targetAccount.userId);
        if (index != -1) {
          _savedAccounts[index] = _savedAccounts[index].copyWith(
            refreshToken: newSession.refreshToken ?? targetAccount.refreshToken,
            lastActive: DateTime.now(),
          );
          await _persistAccounts();
        }

        _isSwitching = false;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to @${targetAccount.username}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return true;
      } else {
        throw Exception("Failed to establish session for @${targetAccount.username}");
      }
    } catch (e) {
      _isSwitching = false;
      notifyListeners();
      LogService.error('Switch account error: $e', tag: 'ACCOUNT_SWITCHER');

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expired for @${targetAccount.username}. Please log in again.'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return false;
    }
  }

  /// Removes an account from saved accounts
  Future<void> removeAccount(String userId) async {
    _savedAccounts.removeWhere((a) => a.userId == userId);
    await _persistAccounts();
    notifyListeners();
  }
}
