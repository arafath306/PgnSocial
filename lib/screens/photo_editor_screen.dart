import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PhotoEditorScreen({super.key, required this.imageBytes});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  ui.Image? _image;
  bool _loading = true;
  bool _isCropping = false;

  // Aspect Ratio Settings
  String _aspectRatio = 'Original'; // 'Original', '1:1', '4:3', '16:9'

  // Image Transformation Settings
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Gesture Helpers
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  // Track the layout size to compute crop math
  Size? _lastViewportSize;
  Size? _lastCropSize;
  double? _lastFittedWidth;
  double? _lastFittedHeight;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error decoding image: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image for editing')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Size _getCropSize(double viewportWidth, double viewportHeight, double imgAspect, String ratio) {
    double maxW = viewportWidth - 48; // padding left and right
    double maxH = viewportHeight - 160; // padding top and bottom for tools

    double aspect = imgAspect;
    if (ratio == '1:1') {
      aspect = 1.0;
    } else if (ratio == '16:9') {
      aspect = 16 / 9;
    } else if (ratio == '4:3') {
      aspect = 4 / 3;
    }

    double w = maxW;
    double h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    return Size(w, h);
  }

  Offset _viewportToImagePixel(
    Offset viewportPoint,
    ui.Image img,
    double viewportW,
    double viewportH,
    double fittedW,
    double fittedH,
    Offset offset,
    double scale,
  ) {
    final double xCentered = (viewportPoint.dx - viewportW / 2 - offset.dx) / scale;
    final double yCentered = (viewportPoint.dy - viewportH / 2 - offset.dy) / scale;

    final double xPixel = ((xCentered / fittedW) + 0.5) * img.width;
    final double yPixel = ((yCentered / fittedH) + 0.5) * img.height;

    return Offset(xPixel, yPixel);
  }

  Future<void> _exportCroppedImage() async {
    if (_image == null ||
        _lastViewportSize == null ||
        _lastCropSize == null ||
        _lastFittedWidth == null ||
        _lastFittedHeight == null) {
      return;
    }

    setState(() => _isCropping = true);

    try {
      final double viewportW = _lastViewportSize!.width;
      final double viewportH = _lastViewportSize!.height;

      final Rect cropRect = Rect.fromCenter(
        center: Offset(viewportW / 2, viewportH / 2),
        width: _lastCropSize!.width,
        height: _lastCropSize!.height,
      );

      final Offset topLeftPixel = _viewportToImagePixel(
        cropRect.topLeft,
        _image!,
        viewportW,
        viewportH,
        _lastFittedWidth!,
        _lastFittedHeight!,
        _offset,
        _scale,
      );

      final Offset bottomRightPixel = _viewportToImagePixel(
        cropRect.bottomRight,
        _image!,
        viewportW,
        viewportH,
        _lastFittedWidth!,
        _lastFittedHeight!,
        _offset,
        _scale,
      );

      final double pLeft = topLeftPixel.dx.clamp(0.0, _image!.width.toDouble());
      final double pTop = topLeftPixel.dy.clamp(0.0, _image!.height.toDouble());
      final double pRight = bottomRightPixel.dx.clamp(0.0, _image!.width.toDouble());
      final double pBottom = bottomRightPixel.dy.clamp(0.0, _image!.height.toDouble());

      final double pWidth = math.max(1.0, pRight - pLeft);
      final double pHeight = math.max(1.0, pBottom - pTop);

      final Rect cropRectInPixels = Rect.fromLTWH(pLeft, pTop, pWidth, pHeight);

      // Create a picture recorder to draw the cropped portion of the image
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.drawImageRect(
        _image!,
        cropRectInPixels,
        Rect.fromLTWH(0, 0, pWidth, pHeight),
        Paint()..filterQuality = ui.FilterQuality.high,
      );

      final croppedImage = await recorder.endRecording().toImage(
            pWidth.round(),
            pHeight.round(),
          );

      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final croppedBytes = byteData.buffer.asUint8List();
        if (mounted) {
          Navigator.pop(context, croppedBytes);
        }
      } else {
        throw Exception("Failed to convert image to bytes");
      }
    } catch (e) {
      debugPrint("Cropping failed: $e");
      if (mounted) {
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to crop the image. Please try again.')),
        );
      }
    }
  }

  Widget _buildRatioChip(String ratio, IconData icon) {
    final isSelected = _aspectRatio == ratio;
    return GestureDetector(
      onTap: () {
        setState(() {
          _aspectRatio = ratio;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              ratio,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Photo',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _loading || _isCropping ? null : _reset,
              child: Text(
                'Reset',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      // Viewport Area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double viewportW = constraints.maxWidth;
                            final double viewportH = constraints.maxHeight;

                            final double imgAspect = _image!.width / _image!.height;

                            // Scale factors to perform aspect fit at scale = 1.0
                            final double fitScaleX = viewportW / _image!.width;
                            final double fitScaleY = viewportH / _image!.height;
                            final double fitScale = math.min(fitScaleX, fitScaleY);

                            final double fittedW = _image!.width * fitScale;
                            final double fittedH = _image!.height * fitScale;

                            final Size cropSize = _getCropSize(viewportW, viewportH, imgAspect, _aspectRatio);

                            // Calculate transformation constraints
                            final double minScale = math.max(cropSize.width / fittedW, cropSize.height / fittedH);
                            final double activeScale = _scale.clamp(minScale, 8.0);

                            final double maxOffsetH = (fittedW * activeScale - cropSize.width) / 2;
                            final double maxOffsetV = (fittedH * activeScale - cropSize.height) / 2;

                            final double activeOffsetX = _offset.dx.clamp(-maxOffsetH, maxOffsetH);
                            final double activeOffsetY = _offset.dy.clamp(-maxOffsetV, maxOffsetV);

                            // Sync variables if clamped
                            if (activeScale != _scale || activeOffsetX != _offset.dx || activeOffsetY != _offset.dy) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _scale = activeScale;
                                    _offset = Offset(activeOffsetX, activeOffsetY);
                                  });
                                }
                              });
                            }

                            // Keep references for export
                            _lastViewportSize = Size(viewportW, viewportH);
                            _lastCropSize = cropSize;
                            _lastFittedWidth = fittedW;
                            _lastFittedHeight = fittedH;

                            final Rect cropRect = Rect.fromCenter(
                              center: Offset(viewportW / 2, viewportH / 2),
                              width: cropSize.width,
                              height: cropSize.height,
                            );

                            return GestureDetector(
                              onScaleStart: (details) {
                                _baseScale = _scale;
                                _baseOffset = _offset;
                                _startFocalPoint = details.localFocalPoint;
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  _scale = (_baseScale * details.scale).clamp(minScale, 8.0);
                                  final Offset delta = details.localFocalPoint - _startFocalPoint;
                                  _offset = _baseOffset + delta;
                                });
                              },
                              child: Stack(
                                children: [
                                  // 1. Draw transformed image
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: ImageCropperPainter(
                                        image: _image!,
                                        scale: _scale,
                                        offset: _offset,
                                        cropSize: cropSize,
                                        fittedWidth: fittedW,
                                        fittedHeight: fittedH,
                                      ),
                                    ),
                                  ),
                                  // 2. Draw black mask overlay with hole & grid lines
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: CropMaskPainter(
                                        cropRect: cropRect,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Tooling Panel (Aspect Ratios)
                      Container(
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        color: Colors.black,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildRatioChip('Original', Icons.image_outlined),
                                  _buildRatioChip('1:1', Icons.crop_square_rounded),
                                  _buildRatioChip('4:3', Icons.crop_3_2_rounded),
                                  _buildRatioChip('16:9', Icons.crop_16_9_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Action Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.inter(
                                        color: Colors.white60,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _isCropping ? null : _exportCroppedImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      'Done',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isCropping)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class ImageCropperPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final Size cropSize;
  final double fittedWidth;
  final double fittedHeight;

  ImageCropperPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.cropSize,
    required this.fittedWidth,
    required this.fittedHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Center transformations
    canvas.translate(size.width / 2, size.height / 2);
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw the image centered
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(-fittedWidth / 2, -fittedHeight / 2, fittedWidth, fittedHeight),
      Paint()..filterQuality = ui.FilterQuality.medium,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ImageCropperPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.cropSize != cropSize ||
        oldDelegate.fittedWidth != fittedWidth ||
        oldDelegate.fittedHeight != fittedHeight;
  }
}

class CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  final Color maskColor;

  CropMaskPainter({required this.cropRect, this.maskColor = Colors.black54});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = maskColor
      ..style = PaintingStyle.fill;

    // Create custom path for viewport overlay (outer boundary minus crop area)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Subtle crop box border
    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(cropRect, borderPaint);

    // Draw rule-of-thirds grid lines
    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Vertical third lines
    final double thirdW = cropRect.width / 3;
    canvas.drawLine(
      Offset(cropRect.left + thirdW, cropRect.top),
      Offset(cropRect.left + thirdW, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + 2 * thirdW, cropRect.top),
      Offset(cropRect.left + 2 * thirdW, cropRect.bottom),
      gridPaint,
    );

    // Horizontal third lines
    final double thirdH = cropRect.height / 3;
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdH),
      Offset(cropRect.right, cropRect.top + thirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + 2 * thirdH),
      Offset(cropRect.right, cropRect.top + 2 * thirdH),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.maskColor != maskColor;
  }
}
