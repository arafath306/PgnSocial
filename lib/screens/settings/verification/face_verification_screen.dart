import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import '../../../widgets/verification/badge_app_bar_title.dart';
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

  // ML Kit Face Detection
  late final FaceDetector _faceDetector;
  bool _isProcessingImage = false;
  int _alignedFramesCount = 0;
  String _guidanceText = "Initializing camera...";
  bool _isScanning = true;
  Color _statusColor = const Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    _faceImage = controller.request.faceImage;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableTracking: true,
      ),
    );

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

    if (_faceImage == null) {
      _initLiveCamera();
    } else {
      _isScanning = false;
    }
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
          imageFormatGroup: Platform.isAndroid 
              ? ImageFormatGroup.nv21 
              : ImageFormatGroup.bgra8888,
        );

        _cameraController = controller;
        await controller.initialize();
        
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
          _guidanceText = "Align your face inside the frame";
          _statusColor = const Color(0xFF6366F1);
        });
        
        _cameraController?.startImageStream(_processCameraImage);
      } else {
        if (mounted) setState(() => _isCameraError = true);
      }
    } catch (e) {
      debugPrint("Live camera initialization error: \$e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraError = true;
        });
      }
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessingImage || _faceImage != null || !mounted) return;
    _isProcessingImage = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessingImage = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      
      if (!mounted || _faceImage != null) return;

      if (faces.isEmpty) {
        _setGuidance("No face detected", Icons.face, const Color(0xFFEF4444));
        _alignedFramesCount = 0;
      } else if (faces.length > 1) {
        _setGuidance("Multiple faces detected", Icons.group_off, const Color(0xFFEF4444));
        _alignedFramesCount = 0;
      } else {
        final face = faces.first;
        final double? rotY = face.headEulerAngleY; // Yaw
        final double? rotX = face.headEulerAngleX; // Pitch

        bool isLookingStraight = false;
        if (rotY != null && rotX != null) {
          if (rotY.abs() < 12 && rotX.abs() < 12) {
            isLookingStraight = true;
          }
        }

        if (isLookingStraight) {
          _alignedFramesCount++;
          if (_alignedFramesCount > 10) { 
            _setGuidance("Capturing...", Icons.camera, const Color(0xFF10B981));
            await _autoCaptureFace();
          } else {
            _setGuidance("Hold Still", Icons.center_focus_strong, const Color(0xFF10B981));
          }
        } else {
          _setGuidance("Look Straight", Icons.straight, const Color(0xFFF59E0B));
          _alignedFramesCount = 0;
        }
      }
    } catch (e) {
      debugPrint("ML Kit error: \$e");
    } finally {
      if (mounted) {
        _isProcessingImage = false;
      }
    }
  }

  void _setGuidance(String text, IconData icon, Color color) {
    if (_guidanceText != text) {
      setState(() {
        _guidanceText = text;
        _statusColor = color;
      });
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _autoCaptureFace() async {
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      
      XFile? capturedFile;
      if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
        capturedFile = await _cameraController!.takePicture();
      }

      if (capturedFile != null && mounted) {
        setState(() {
          _faceImage = capturedFile;
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint("Auto capture error: \$e");
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isCameraError = true;
        });
      }
    }
  }

  Future<void> _fallbackManualCamera() async {
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
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
      debugPrint("Manual camera picker error: \$e");
    }
  }

  void _retakeScan() {
    setState(() {
      _faceImage = null;
      _isScanning = true;
      _alignedFramesCount = 0;
      _guidanceText = "Initializing camera...";
    });
    if (!_isCameraInitialized && !_isCameraError) {
      _initLiveCamera();
    } else if (_isCameraInitialized && _cameraController != null) {
      _cameraController!.startImageStream(_processCameraImage);
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
  void dispose() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector.close();
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
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
        title: BadgeAppBarTitle(
          isBusiness: req.isBusiness,
          isGovernment: req.isGovernment,
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

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: captured
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : _statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: captured
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : _statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: captured ? const Color(0xFF10B981) : _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            captured ? '✓ Face Captured' : _guidanceText,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: captured ? const Color(0xFF10B981) : _statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    ScaleTransition(
                      scale: _pulseAnim,
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _scannerController,
                              builder: (ctx, _) => CustomPaint(
                                size: const Size(250, 250),
                                painter: BiometricScannerPainter(
                                  color: captured ? const Color(0xFF10B981) : _statusColor,
                                  animationValue: _scannerController.value,
                                ),
                              ),
                            ),
                            
                            // Rigid 204x204 container for the camera to prevent bouncing
                            Container(
                              width: 204,
                              height: 204,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: captured
                                  ? FutureBuilder<Uint8List>(
                                      future: _faceImage!.readAsBytes(),
                                      builder: (ctx, snap) {
                                        if (!snap.hasData) {
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                                        }
                                        return Image.memory(snap.data!, fit: BoxFit.cover);
                                      },
                                    )
                                  : (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
                                      ? FittedBox(
                                          fit: BoxFit.cover,
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: _cameraController!.value.previewSize?.height ?? 204,
                                            height: _cameraController!.value.previewSize?.width ?? 204,
                                            child: CameraPreview(_cameraController!),
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
                                                  _isCameraError ? 'Tap to Enable Camera' : 'Initializing...',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    color: context.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                            ),

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
                                            _statusColor,
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _statusColor.withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            if (captured)
                              Positioned(
                                bottom: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_isCameraError && !captured) ...[
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

                    if (captured) ...[
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
