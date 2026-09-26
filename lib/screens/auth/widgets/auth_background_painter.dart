// NOTE: [UNUSED / REFERENCE ONLY]
// This atmospheric custom painter is currently not active in auth screens.
// Kept for future visual theme animations or background graphics reference.

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AtmosphericBackgroundPainter extends CustomPainter {
  final double cloudOffset;
  final bool isDark;

  AtmosphericBackgroundPainter({
    required this.cloudOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(cloudOffset * 2 * math.pi);
    final drift2 = math.cos(cloudOffset * 2 * math.pi);

    // Light mode: soft blue/indigo tones; dark: purple nebula
    final c1 = isDark ? const Color(0xFF3D1F8C) : const Color(0xFF5B7FFF);
    final c2 = isDark ? const Color(0xFF1E0F5E) : const Color(0xFF7B5FFF);
    final c3 = isDark ? const Color(0xFF5B21B6) : const Color(0xFF5B7FFF);
    final c4 = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF3B82F6);
    final c5 = isDark ? const Color(0xFF7C3AED) : const Color(0xFF5B7FFF);

    final baseAlpha = isDark ? 0.42 : 0.08;

    // Center glow
    final glowAlpha = baseAlpha + 0.08 * drift;
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          c1.withValues(alpha: glowAlpha.clamp(0.0, 1.0)),
          c2.withValues(alpha: (glowAlpha * 0.5).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.1),
        radius: size.width * 0.9,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.1),
      size.width * 0.9,
      centerGlow,
    );

    // Left cloud
    final leftX = size.width * 0.08 + 28.0 * drift;
    final leftY = size.height * 0.32 + 14.0 * drift2;
    final leftCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c3.withValues(
              alpha: (isDark ? 0.20 : 0.07 + 0.03 * drift).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(leftX, leftY),
        radius: size.width * 0.48,
      ));
    canvas.drawCircle(Offset(leftX, leftY), size.width * 0.48, leftCloud);

    // Right cloud
    final rightX = size.width * 0.92 - 22.0 * drift;
    final rightY = size.height * 0.22 - 12.0 * drift2;
    final rightCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c4.withValues(
              alpha: (isDark ? 0.17 : 0.06 + 0.02 * drift2).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(rightX, rightY),
        radius: size.width * 0.42,
      ));
    canvas.drawCircle(Offset(rightX, rightY), size.width * 0.42, rightCloud);

    // Bottom accent cloud
    final accentX = size.width * 0.22 + 18.0 * drift2;
    final accentY = size.height * 0.72 + 8.0 * drift;
    final accentCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c5.withValues(
              alpha: (isDark ? 0.11 : 0.05 + 0.03 * drift.abs())
                  .clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(accentX, accentY),
        radius: size.width * 0.32,
      ));
    canvas.drawCircle(Offset(accentX, accentY), size.width * 0.32, accentCloud);

    // Bottom fade
    final fadeColors = isDark
        ? [Colors.transparent, const Color(0x99080A18), const Color(0xFF080A18)]
        : [Colors.transparent, const Color(0x22EEF4FB), const Color(0xFFE8F0F8)];
    final fadeOut = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fadeColors,
        stops: const [0.42, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fadeOut);
  }

  @override
  bool shouldRepaint(AtmosphericBackgroundPainter old) =>
      old.cloudOffset != cloudOffset || old.isDark != isDark;
}
