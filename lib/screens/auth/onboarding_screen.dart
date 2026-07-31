import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'captcha_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(bool startSignUp) onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0 for intro screen, 1 for globe options screen

  double _cardDragOffset = 0.0;
  bool _isDraggingCard = false;

  void _nextStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _currentStep == 1 ? Brightness.light : Brightness.dark,
    ));

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep == 1) {
          setState(() {
            _currentStep = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: _currentStep == 1 ? const Color(0xFF041C15) : Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _currentStep == 1 ? _buildSecondScreen() : _buildFirstScreen(),
        ),
      ),
    );
  }

  // ── First Screen (Intro) ───────────────────────────────────────────────────
  Widget _buildFirstScreen() {
    return Stack(
      key: const ValueKey('first_screen'),
      children: [
        // Vector background image
        Positioned.fill(
          child: Image.asset(
            'assets/onboarding_bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // Content Overlay
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Animated GIF Banner above Welcome to Pigeon (Transparent, mini size)
                  SizedBox(
                    width: 65,
                    height: 65,
                    child: Image.asset(
                      'assets/15911180.gif',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titles
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Welcome to Pigeon',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Your community, instantly connected',
                          style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                              height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Navigation Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dot indicators (2 dots for 2 main onboarding screen steps)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(2, (index) {
                            final isActive = _currentStep == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive
                                    ? const Color(0xFF1E824C)
                                    : const Color(0xFF1E824C).withValues(alpha: 0.24),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Gradient Continue button
                        _GradientButton(
                          label: 'Continue >',
                          onTap: _nextStep,
                        ),

                        const SizedBox(height: 18),

                        // Made by NGST
                        Text(
                          'Made by NGST',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Second Screen (Options Selection Card) ─────────────────────────────────
  Widget _buildSecondScreen() {
    final double maxDragDistance = 240.0;
    final double dragProgress = (_cardDragOffset / maxDragDistance).clamp(0.0, 1.0);

    return Stack(
      key: const ValueKey('second_screen'),
      children: [
        // Dark green globe background image
        Positioned.fill(
          child: Opacity(
            opacity: 0.70,
            child: Image.asset(
              'assets/onboarding_bg_3.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient overlay for better text contrast at top
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF041C15).withValues(alpha: 0.75),
                  Colors.transparent,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Content
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              bottom: false, // Card spans to the bottom of screen
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Back Button
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _currentStep = 0;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header Texts (Translates down to center when card is dragged down)
                  AnimatedContainer(
                    duration: _isDraggingCard ? Duration.zero : const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, dragProgress * 140.0, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join millions\naround the world',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Green capsule divider
                        Container(
                          width: 48,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Connect, share and grow with\npeople who matter.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom white card with options (Draggable & Responsive Spring Physics)
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _isDraggingCard = true;
                        _cardDragOffset = (_cardDragOffset + details.delta.dy).clamp(0.0, maxDragDistance);
                      });
                    },
                    onVerticalDragEnd: (_) {
                      setState(() {
                        _isDraggingCard = false;
                        _cardDragOffset = 0.0;
                      });
                    },
                    child: AnimatedContainer(
                      duration: _isDraggingCard ? Duration.zero : const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      transform: Matrix4.translationValues(0, _cardDragOffset, 0),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle Pill Indicator
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              width: 38,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),

                          Text(
                            'What would you like to do?',
                            style: GoogleFonts.inter(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Option 1: Create Account
                        _buildOptionCard(
                          title: 'Create Account',
                          subtitle: 'Sign up and start your journey with Pigeon.',
                          icon: Icons.person_add_rounded,
                          iconGradient: const [Color(0xFF1E824C), Color(0xFF2ECC71)],
                          titleColor: const Color(0xFF1E824C),
                          bgColor: const Color(0xFF1E824C).withValues(alpha: 0.05),
                          borderColor: const Color(0xFF1E824C).withValues(alpha: 0.12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaptchaScreen(
                                isSignup: true,
                                onPass: () {
                                  Navigator.pop(context);
                                  widget.onFinish(true);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Option 2: Log In
                        _buildOptionCard(
                          title: 'Log In',
                          subtitle: 'Already have an account? Log in to continue.',
                          icon: Icons.person_rounded,
                          iconGradient: const [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                          titleColor: const Color(0xFF1A365D),
                          bgColor: const Color(0xFF1A365D).withValues(alpha: 0.05),
                          borderColor: const Color(0xFF1A365D).withValues(alpha: 0.12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaptchaScreen(
                                isSignup: false,
                                onPass: () {
                                  Navigator.pop(context);
                                  widget.onFinish(false);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Security Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF1E824C),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Secure. Private. Yours.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required Color titleColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: titleColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E824C), Color(0xFF2ECC71)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E824C).withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
