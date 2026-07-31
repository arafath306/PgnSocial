import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/dak_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isSignedIn = authService.isUserSignedIn;
    final isEmailVerified = authService.isEmailVerified;

    if (isSignedIn) {
      if (!isEmailVerified) {
        context.go('/verify-email');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Perfectly centered logo to match native splash screen
          const Center(
            child: DakLogo(size: 160),
          ),
          
          // App Name below the logo
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 240), // 160/2 + spacing
              child: Text(
                'Pigeon',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF1E824C),
                ),
              ),
            ),
          ),
          
          // Loading indicator at bottom
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 48.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
