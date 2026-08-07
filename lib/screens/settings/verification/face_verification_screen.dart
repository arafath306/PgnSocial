import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;

  final _picker = ImagePicker();
  XFile? _faceImage;

  late AnimationController _scannerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  int _currentStep = 0;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  Timer? _scanTimer;

  List<_AiStep> get _aiSteps => [
    _AiStep(
      icon: Icons.face_retouching_natural_rounded,
      label: 'Look Straight',
      subLabel: 'Position your face inside the oval frame.',
      color: const Color(0xFF6366F1),
    ),
    _AiStep(
      icon: Icons.center_focus_strong_rounded,
      label: 'Hold Still',
      subLabel: 'Keep steady while live biometric scan completes.',
      color: const Color(0xFF06B6D4),
    ),
    _AiStep(
      icon: Icons.remove_red_eye_outlined,
      label: 'Blink & Capture',
      subLabel: 'Blink naturally for auto-capture.',
      color: const Color(0xFF10B981),
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

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initLiveCamera();
  }

  Future<void> _initLiveCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        final controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        _cameraController = controller;
        await controller.initialize();
        
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
        });
      } else {
        if (mounted) setState(() => _isCameraError = true);
      }
    } catch (e) {
      debugPrint("Live camera initialization error: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _retryCameraOrPick() async {
    setState(() {
      _isCameraError = false;
      _isCameraInitialized = false;
    });
    await _initLiveCamera();
    if (!_isCameraInitialized && mounted) {
      // If camera plugin fails or lacks permission, use ImagePicker which triggers OS permission dialog
      await _fallbackManualCamera();
    }
  }

  void _startLiveScan() async {
    if (_isScanning) return;

    if (!_isCameraInitialized) {
      await _retryCameraOrPick();
      if (!_isCameraInitialized && _faceImage == null) return;
    }

    if (_faceImage != null) return;

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _currentStep = 0;
    });

    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _scanProgress += 0.02;
        if (_scanProgress >= 0.35 && _currentStep == 0) {
          _currentStep = 1;
        } else if (_scanProgress >= 0.70 && _currentStep == 1) {
          _currentStep = 2;
        }

        if (_scanProgress >= 1.0) {
          _scanProgress = 1.0;
          timer.cancel();
          _autoCaptureFace();
        }
      });
    });
  }

  Future<void> _autoCaptureFace() async {
    try {
      XFile? capturedFile;
      if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
        capturedFile = await _cameraController!.takePicture();
      } else {
        capturedFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          preferredCameraDevice: CameraDevice.front,
        );
      }

      if (capturedFile != null && mounted) {
        setState(() {
          _faceImage = capturedFile;
          _isScanning = false;
        });
      } else if (mounted) {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      debugPrint("Auto capture error: $e");
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _fallbackManualCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked != null && mounted) {
        setState(() {
          _faceImage = picked;
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint("Manual camera picker error: $e");
    }
  }

  void _retakeScan() {
    setState(() {
      _faceImage = null;
      _isScanning = false;
      _scanProgress = 0.0;
      _currentStep = 0;
    });
    if (!_isCameraInitialized && !_isCameraError) {
      _initLiveCamera();
    }
  }

  void _onContinue() {
    if (_faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseCompleteFaceVerificationToContinue,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
    final req = context.watch<VerificationController>().request;
    final steps = VerificationController.getSteps(req.category);

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
        title: Text(
          req.isBusiness
              ? "Apply for Gold Badge 👑"
              : (req.isGovernment ? "Apply for Gray Badge 🏛️" : "Apply for Blue Badge 🔵"),
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Title
                    Text(
                      AppLocalizations.of(context)!.faceVerification,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      captured
                          ? 'Face photo captured successfully. Review and proceed.'
                          : 'Live In-App Scanner. Align your face inside the frame.',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // AI STATUS CHIP
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: captured
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : (_isScanning ? step.color.withValues(alpha: 0.15) : context.primaryAccent.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: captured
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : (_isScanning ? step.color.withValues(alpha: 0.4) : context.primaryAccent.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: captured
                                  ? const Color(0xFF10B981)
                                  : (_isScanning ? step.color : context.primaryAccent),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            captured
                                ? '✓  Face Verified & Captured'
                                : (_isScanning
                                    ? 'Scanning (${(_scanProgress * 100).toInt()}%)'
                                    : 'Live Camera Ready'),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: captured
                                  ? const Color(0xFF10B981)
                                  : (_isScanning ? step.color : context.primaryAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // LIVE BIOMETRIC CAMERA OVAL FRAME
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: GestureDetector(
                        onTap: captured ? null : _retryCameraOrPick,
                        child: SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated Biometric Scanner Ring Brackets
                              AnimatedBuilder(
                                animation: _scannerController,
                                builder: (ctx, _) => CustomPaint(
                                  size: const Size(250, 250),
                                  painter: BiometricScannerPainter(
                                    color: captured
                                        ? const Color(0xFF10B981)
                                        : (_isScanning ? step.color : context.primaryAccent),
                                    animationValue: _scannerController.value,
                                  ),
                                ),
                              ),

                              // Oval Clip Frame for Live Camera Preview or Captured Image
                              ClipOval(
                                child: SizedBox(
                                  width: 204,
                                  height: 204,
                                  child: captured
                                      ? FutureBuilder<Uint8List>(
                                          future: _faceImage!.readAsBytes(),
                                          builder: (ctx, snap) {
                                            if (!snap.hasData) {
                                              return const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2.5),
                                              );
                                            }
                                            return Image.memory(snap.data!, fit: BoxFit.cover);
                                          },
                                        )
                                       : (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
                                           ? OverflowBox(
                                               alignment: Alignment.center,
                                               child: FittedBox(
                                                 fit: BoxFit.cover,
                                                 child: SizedBox(
                                                   width: 204,
                                                   height: 204 / (_cameraController!.value.aspectRatio == 0 ? 1 : _cameraController!.value.aspectRatio),
                                                   child: CameraPreview(_cameraController!),
                                                 ),
                                               ),
                                             )
                                          : Container(
                                              color: isDark ? const Color(0xFF0F1123) : const Color(0xFFF1F5FF),
                                              padding: const EdgeInsets.all(16),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      _isCameraError ? Icons.camera_enhance_rounded : Icons.videocam_rounded,
                                                      size: 42,
                                                      color: context.primaryAccent,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      _isCameraError ? 'Tap to Enable Camera' : 'Initializing Live Cam...',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12.5,
                                                        color: context.textPrimary,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    if (_isCameraError) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Grant camera permission',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          color: context.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                ),
                              ),

                            // Laser Scanner Sweep Animation line (When scanning)
                            if (_isScanning && !captured)
                              AnimatedBuilder(
                                animation: _scannerController,
                                builder: (ctx, _) {
                                  final pos = 22 + (_scannerController.value * 204);
                                  return Positioned(
                                    top: pos,
                                    child: Container(
                                      width: 204,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            step.color,
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: step.color.withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Checkmark Pill on capture
                            if (captured)
                              Positioned(
                                bottom: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                    // INSTRUCTION & ACTION SECTION
                    if (!captured) ...[
                      // Dynamic Guidance Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: step.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: step.color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: step.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step.icon, color: step.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.subLabel,
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
                      const SizedBox(height: 24),

                      // Start In-App Scan Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _startLiveScan,
                          icon: _isScanning
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_front_rounded, size: 20),
                          label: Text(
                            _isScanning ? 'Scanning Live Face...' : 'Start Live Verification',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: step.color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      if (_isCameraError) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _fallbackManualCamera,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: Text(
                            'Or Take Photo With Camera',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ] else ...[
                      // Retake button if captured
                      OutlinedButton.icon(
                        onPressed: _retakeScan,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          'Retake Face Photo',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Continue Button at bottom
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

// Biometric Scanner Ring Painter
class BiometricScannerPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  BiometricScannerPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final paintRing = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintRing);

    final paintArc = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = animationValue * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      1.2,
      false,
      paintArc,
    );
  }

  @override
  bool shouldRepaint(covariant BiometricScannerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.animationValue != animationValue;
  }
}
