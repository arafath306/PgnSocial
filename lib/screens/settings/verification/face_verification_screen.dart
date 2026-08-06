import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'review_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  XFile? _faceImage;

  late AnimationController _scannerController;
  late AnimationController _pulseController;
  late AnimationController _instructionController;
  late Animation<double> _pulseAnim;
  late Animation<double> _instructionFade;

  int _currentStep = 0;
  bool _isCapturing = false;

  static const _steps = ['Personal', 'Identity', 'Face', 'Review', 'Payment'];

  // Crypto-style AI face check steps
  List<_AiStep> get _aiSteps => [
    _AiStep(
      icon: Icons.face_retouching_natural_rounded,
      label: AppLocalizations.of(context)!.lookStraight,
      subLabel: 'Face the camera directly. Keep a neutral expression.',
      color: Color(0xFF6366F1),
    ),
    _AiStep(
      icon: Icons.rotate_left_rounded,
      label: AppLocalizations.of(context)!.turnLeftSlightly,
      subLabel: 'Slowly rotate your head to the left about 15°.',
      color: Color(0xFF8B5CF6),
    ),
    _AiStep(
      icon: Icons.rotate_right_rounded,
      label: AppLocalizations.of(context)!.turnRightSlightly,
      subLabel: 'Slowly rotate your head to the right about 15°.',
      color: Color(0xFF06B6D4),
    ),
    _AiStep(
      icon: Icons.remove_red_eye_outlined,
      label: AppLocalizations.of(context)!.blinkNaturally,
      subLabel: 'Blink both eyes once to confirm liveness.',
      color: Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    _faceImage = controller.request.faceImage;

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _instructionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _instructionFade = CurvedAnimation(
      parent: _instructionController,
      curve: Curves.easeIn,
    );
    _instructionController.forward();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _aiSteps.length - 1) {
      _instructionController.reverse().then((_) {
        setState(() => _currentStep++);
        _instructionController.forward();
      });
    } else {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    setState(() => _isCapturing = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked != null) {
        setState(() {
          _faceImage = picked;
          _isCapturing = false;
        });
      } else {
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  void _retake() {
    setState(() {
      _faceImage = null;
      _currentStep = 0;
    });
    _instructionController.reset();
    _instructionController.forward();
  }

  void _onContinue() {
    if (_faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseCompleteFaceVerificationToContinue,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    context.read<VerificationController>().updateFaceImage(_faceImage);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final step = _aiSteps[_currentStep];
    final bool captured = _faceImage != null;
    final steps = VerificationController.getSteps();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.applyForBlueBadge,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepProgressBar(currentStep: 3, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Text(AppLocalizations.of(context)!.faceVerification,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      captured
                          ? 'Your face has been captured successfully.'
                          : 'Follow the on-screen instructions carefully.',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── AI STATUS CHIP ───────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: captured
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : step.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: captured
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : step.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: captured ? const Color(0xFF10B981) : step.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            captured ? '✓  Identity Captured' : '  AI Scanner Active',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: captured ? const Color(0xFF10B981) : step.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── BIOMETRIC FACE FRAME ─────────────────────────────
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: GestureDetector(
                        onTap: captured ? null : (_currentStep == _aiSteps.length - 1 ? _openCamera : null),
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated biometric brackets
                              AnimatedBuilder(
                                animation: _scannerController,
                                builder: (ctx, _) => CustomPaint(
                                  size: const Size(240, 240),
                                  painter: BiometricScannerPainter(
                                    color: captured
                                        ? const Color(0xFF10B981)
                                        : step.color,
                                    animationValue: _scannerController.value,
                                  ),
                                ),
                              ),
                              // Face oval frame
                              ClipOval(
                                child: SizedBox(
                                  width: 196,
                                  height: 196,
                                  child: captured
                                      ? FutureBuilder<Uint8List>(
                                          future: _faceImage!.readAsBytes(),
                                          builder: (ctx, snap) {
                                            if (!snap.hasData) {
                                              return const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              );
                                            }
                                            return Image.memory(snap.data!, fit: BoxFit.cover);
                                          },
                                        )
                                      : Container(
                                          color: isDark
                                              ? const Color(0xFF0F1123)
                                              : const Color(0xFFF1F5FF),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              AnimatedBuilder(
                                                animation: _instructionFade,
                                                builder: (ctx, child) => Opacity(
                                                  opacity: _instructionFade.value,
                                                  child: child,
                                                ),
                                                child: Icon(
                                                  step.icon,
                                                  size: 52,
                                                  color: step.color,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Step ${_currentStep + 1} / ${_aiSteps.length}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: context.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              // Scan line (only when not captured)
                              if (!captured)
                                AnimatedBuilder(
                                  animation: _scannerController,
                                  builder: (ctx, _) {
                                    final pos = 22 + (_scannerController.value * 196);
                                    return Positioned(
                                      top: pos,
                                      child: Container(
                                        width: 196,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              step.color.withValues(alpha: 0.9),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: step.color.withValues(alpha: 0.6),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              // Success tick
                              if (captured)
                                Positioned(
                                  bottom: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── INSTRUCTION CARD ─────────────────────────────────
                    if (!captured) ...[
                      FadeTransition(
                        opacity: _instructionFade,
                        child: _InstructionCard(step: step, isDark: isDark),
                      ),
                      const SizedBox(height: 20),

                      // Step dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_aiSteps.length, (i) {
                          final active = i == _currentStep;
                          final done = i < _currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF10B981)
                                  : active
                                      ? _aiSteps[_currentStep].color
                                      : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Action button: Next step or Open Camera
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton.icon(
                            onPressed: _isCapturing ? null : _nextStep,
                            icon: _isCapturing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _currentStep == _aiSteps.length - 1
                                        ? Icons.camera_alt_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              _currentStep == _aiSteps.length - 1
                                  ? 'Open Camera & Capture'
                                  : 'Next Step',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _aiSteps[_currentStep].color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // ── CAPTURED SUCCESS CARD ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.faceCaptured,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(AppLocalizations.of(context)!.yourSelfieIsReadyForIdentityMatching,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _retake,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.retakePhoto, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          foregroundColor: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── SECURITY BADGES ──────────────────────────────────
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _Badge(icon: Icons.security_rounded, label: AppLocalizations.of(context)!.endtoendEncrypted),
                        _Badge(icon: Icons.visibility_off_rounded, label: AppLocalizations.of(context)!.notStoredPublicly),
                        _Badge(icon: Icons.verified_user_rounded, label: AppLocalizations.of(context)!.livenessChecked),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM CONTINUE BUTTON ───────────────────────────────
            if (captured)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: PigeonPrimaryButton(
                  label: AppLocalizations.of(context)!.saveContinue,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _onContinue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Instruction card widget ───────────────────────────────────────────────────
class _InstructionCard extends StatelessWidget {
  final _AiStep step;
  final bool isDark;
  const _InstructionCard({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: step.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: step.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: step.color,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Security badge widget ─────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: context.isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Step model ─────────────────────────────────────────────────────────────
class _AiStep {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  const _AiStep({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
  });
}

// ── Biometric scanner painter ─────────────────────────────────────────────────
class BiometricScannerPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  BiometricScannerPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double pulseScale = 1.0 + (animationValue * 0.025);
    final double radius = (size.width / 2) * pulseScale;
    final center = Offset(size.width / 2, size.height / 2);

    // Outer glow circle
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius - 6, glowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 6, ringPaint);

    // Corner brackets
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const bracketLength = 26.0;
    const offset = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius + offset, center.dy - radius + offset + bracketLength)
        ..lineTo(center.dx - radius + offset, center.dy - radius + offset)
        ..lineTo(center.dx - radius + offset + bracketLength, center.dy - radius + offset),
      bracketPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - offset - bracketLength, center.dy - radius + offset)
        ..lineTo(center.dx + radius - offset, center.dy - radius + offset)
        ..lineTo(center.dx + radius - offset, center.dy - radius + offset + bracketLength),
      bracketPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius + offset, center.dy + radius - offset - bracketLength)
        ..lineTo(center.dx - radius + offset, center.dy + radius - offset)
        ..lineTo(center.dx - radius + offset + bracketLength, center.dy + radius - offset),
      bracketPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - offset - bracketLength, center.dy + radius - offset)
        ..lineTo(center.dx + radius - offset, center.dy + radius - offset)
        ..lineTo(center.dx + radius - offset, center.dy + radius - offset - bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BiometricScannerPainter old) =>
      old.animationValue != animationValue || old.color != color;
}
