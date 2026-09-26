import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings/verification/verification_intro_screen.dart';
import '../utils/app_theme.dart';

/// Shows an upgrade bottom sheet modal prompting the user to upgrade to a Premium plan.
void showUpgradePremiumSheet({
  required BuildContext context,
  required String title,
  required String description,
  required IconData icon,
  required Color iconColor,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ctx.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: ctx.border, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("👑 ", style: TextStyle(fontSize: 18)),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ctx.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ctx.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationIntroScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E824C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Upgrade to Premium Plan",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Maybe Later",
              style: GoogleFonts.inter(
                color: ctx.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Convenience paywall prompt specifically for Voice Comments.
void showVoiceCommentPremiumPaywall(BuildContext context) {
  showUpgradePremiumSheet(
    context: context,
    title: "Voice Comments (Premium Feature)",
    description:
        "Voice comments allow you to record and share high-quality audio notes in discussions. Upgrade to any Premium plan to unlock Voice Comments!",
    icon: Icons.mic_rounded,
    iconColor: const Color(0xFF1E824C),
  );
}
