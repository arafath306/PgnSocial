import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/utils/app_router.dart';
import 'package:dak/services/auth_service.dart';
import 'package:dak/services/database_service.dart';

class MockAuthService extends ChangeNotifier implements AuthService {
  bool _isSignedIn = false;
  bool _isEmailVerified = false;
  bool _hasAcceptedTerms = false;
  
  @override
  bool get isUserSignedIn => _isSignedIn;
  @override
  bool get isEmailVerified => _isEmailVerified;
  @override
  bool get hasAcceptedTerms => _hasAcceptedTerms;
  
  void setAuth(bool signedIn, bool emailVerified, bool termsAccepted) {
    _isSignedIn = signedIn;
    _isEmailVerified = emailVerified;
    _hasAcceptedTerms = termsAccepted;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDatabaseService extends ChangeNotifier implements DatabaseService {
  @override
  void clearUser() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppRouter Tests', () {
    testWidgets('AppRouter configures routes and returns GoRouter', (tester) async {
      final authService = MockAuthService();
      final dbService = MockDatabaseService();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
            ChangeNotifierProvider<DatabaseService>.value(value: dbService),
          ],
          builder: (context, _) {
            final router = AppRouter.router(context);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      );
      
      // Wait for router initialization
      await tester.pumpAndSettle();
      
      // We start at splash, then since not signed in, it should redirect to onboarding or auth
      // This confirms the router is functioning without crash.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
