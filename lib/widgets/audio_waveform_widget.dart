import 'dart:math';
import 'package:flutter/material.dart';

/// Interactive audio waveform visualizer widget.
/// Renders vertical amplitude bars that highlight as audio plays
/// and allows tapping/dragging to seek directly.
class AudioWaveformWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final ValueChanged<double>? onSeek;
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;
  final String? seedKey;
  final double height;

  const AudioWaveformWidget({
    super.key,
    required this.progress,
    this.onSeek,
    required this.activeColor,
    required this.inactiveColor,
    this.barCount = 30,
    this.seedKey,
    this.height = 36.0,
  });

  List<double> _generateHeights() {
    final seed = seedKey != null ? seedKey.hashCode : 42;
    final random = Random(seed);
    final List<double> heights = [];
    for (int i = 0; i < barCount; i++) {
      // Generate pleasing wave height values between 0.2 and 1.0
      final h = 0.25 + 0.75 * sin((i / barCount) * pi).abs() * (0.6 + 0.4 * random.nextDouble());
      heights.add(h.clamp(0.2, 1.0));
    }
    return heights;
  }

  void _handleSeek(Offset localPosition, double width) {
    if (onSeek == null || width <= 0) return;
    final double fraction = (localPosition.dx / width).clamp(0.0, 1.0);
    onSeek!(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final heights = _generateHeights();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          onTapDown: (details) => _handleSeek(details.localPosition, totalWidth),
          onHorizontalDragUpdate: (details) => _handleSeek(details.localPosition, totalWidth),
          child: Container(
            height: height,
            color: Colors.transparent,
            child: CustomPaint(
              size: Size(totalWidth, height),
              painter: _WaveformPainter(
                progress: progress.clamp(0.0, 1.0),
                heights: heights,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> heights;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.heights,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final int count = heights.length;
    final double gap = 2.5;
    final double availableWidth = size.width - (gap * (count - 1));
    final double barWidth = max(2.0, availableWidth / count);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final double x = i * (barWidth + gap);
      final double barFraction = (i + 0.5) / count;
      final bool isActive = barFraction <= progress;

      final double barHeight = heights[i] * size.height;
      final double y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, isActive ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.heights != heights;
  }
}
