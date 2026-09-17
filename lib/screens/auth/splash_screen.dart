import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  Timer? _navigationTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();

    // Show splash for 1.8 seconds then navigate
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isSignedIn = authService.isUserSignedIn;
    final isEmailVerified = authService.isEmailVerified;
    final hasAcceptedTerms = authService.hasAcceptedTerms;

    if (isSignedIn) {
      if (!isEmailVerified) {
        context.go('/verify-email');
      } else if (!hasAcceptedTerms) {
        context.go('/terms-acceptance');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splashBgColor = Color(0xFF0C2052);

    return Scaffold(
      backgroundColor: splashBgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/splash.png',
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
