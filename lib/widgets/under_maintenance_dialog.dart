// NOTE: [UNUSED / REFERENCE ONLY]
// This maintenance dialog is currently not actively triggered in the app.
// Kept for future server maintenance notifications or downtime handling.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showUnderMaintenanceDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bgColor = isDark ? const Color(0xFF090A0F) : const Color(0xFFF9FAFB);
      final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
      final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      const accentColor = Color(0xFF1E824C);

      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Under Maintenance",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Chat feature is currently undergoing scheduled maintenance. Stay tuned!",
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: subTextColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        foregroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
