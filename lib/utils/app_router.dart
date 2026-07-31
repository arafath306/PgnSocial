import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/email_verification_pending_screen.dart';
import '../screens/auth/terms_acceptance_screen.dart';
import '../screens/main_screen.dart';

class AppRouter {
  static bool _showOnboarding = true;

  static GoRouter router(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggingIn = state.matchedLocation == '/auth';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isSplash = state.matchedLocation == '/splash';
        final isVerifying = state.matchedLocation == '/verify-email';
        final isTermsAcceptance = state.matchedLocation == '/terms-acceptance';

        final isSignedIn = authService.isUserSignedIn;
        final isEmailVerified = authService.isEmailVerified;
        final hasAcceptedTerms = authService.hasAcceptedTerms;

        // Allow splash screen to render smoothly before redirecting
        if (isSplash) {
          return null;
        }

        // If signed in
        if (isSignedIn) {
          if (!isEmailVerified) {
            return '/verify-email';
          }
          if (!hasAcceptedTerms) {
            if (!isTermsAcceptance) {
              return '/terms-acceptance';
            }
            return null;
          }
          if (isLoggingIn || isOnboarding || isVerifying || isTermsAcceptance) {
            return '/home';
          }
          return null; // Keep current path
        }

        // Signed out
        dbService.clearUser();

        if (!isLoggingIn && !isOnboarding) {
          return _showOnboarding ? '/onboarding' : '/auth';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingScreen(
            onFinish: (startSignUp) {
              _showOnboarding = false;
              // Navigate to auth
              context.go(startSignUp ? '/auth?signup=true' : '/auth?signup=false');
            },
          ),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            final signupParam = state.uri.queryParameters['signup'] == 'true';
            return AuthScreen(
              initialIsSignUp: signupParam,
              onLoginSuccess: () {
                // AuthState listener will redirect automatically
              },
            );
          },
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const EmailVerificationPendingScreen(),
        ),
        GoRoute(
          path: '/terms-acceptance',
          builder: (context, state) => TermsAcceptanceScreen(
            onAccepted: () {
              authService.markTermsAccepted();
              context.go('/home');
            },
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainScreen(),
        ),
      ],
    );
  }
}
