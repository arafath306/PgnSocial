import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';

class IdUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const IdUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUploaded = file != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: isUploaded
              ? null
              : DashedRRectBorderPainter(
                  color: context.primaryAccent.withValues(alpha: 0.35),
                  strokeWidth: 1.5,
                  radius: 20,
                  dashWidth: 6,
                  dashGap: 4,
                ),
          child: Container(
            height: 165,
            decoration: BoxDecoration(
              color: isUploaded
                  ? context.cardBg
                  : context.primaryAccent.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(20),
              border: isUploaded
                  ? Border.all(color: context.primaryAccent, width: 2)
                  : null,
              boxShadow: isUploaded
                  ? [
                      BoxShadow(
                        color: context.primaryAccent.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: isUploaded
                ? _buildUploadedState(context)
                : _buildEmptyState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Stack(
      children: [
        // Subtle corner guides (Scanner Viewfinder feel)
        Positioned(
          top: 14,
          left: 14,
          child: _CornerGuide(isTop: true, isLeft: true, color: context.primaryAccent.withValues(alpha: 0.4)),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: _CornerGuide(isTop: true, isLeft: false, color: context.primaryAccent.withValues(alpha: 0.4)),
        ),
        Positioned(
          bottom: 14,
          left: 14,
          child: _CornerGuide(isTop: false, isLeft: true, color: context.primaryAccent.withValues(alpha: 0.4)),
        ),
        Positioned(
          bottom: 14,
          right: 14,
          child: _CornerGuide(isTop: false, isLeft: false, color: context.primaryAccent.withValues(alpha: 0.4)),
        ),

        // Central Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Badge with Glow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryAccent.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  color: context.primaryAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedState(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image Preview
        FutureBuilder<Uint8List>(
          future: file!.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.primaryAccent,
                ),
              );
            }
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          },
        ),

        // Gradient overlay for contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // Top Left: Success Verified Badge
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  'Photo Uploaded',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top Right: Retake / Change Action Pill
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cameraswitch_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Change',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Left Title Label
        Positioned(
          left: 14,
          bottom: 12,
          right: 14,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Corner guides painter helper
class _CornerGuide extends StatelessWidget {
  final bool isTop;
  final bool isLeft;
  final Color color;

  const _CornerGuide({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const double length = 12;
    const double width = 2;

    return CustomPaint(
      size: const Size(length, length),
      painter: _CornerPainter(isTop: isTop, isLeft: isLeft, color: color, strokeWidth: width),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;
  final double strokeWidth;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

// Dashed Border Painter for Rounded Rectangles
class DashedRRectBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashGap;

  DashedRRectBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
