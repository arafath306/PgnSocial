import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class BadgeAppBarTitle extends StatelessWidget {
  final bool isBusiness;
  final bool isGovernment;

  const BadgeAppBarTitle({
    super.key,
    this.isBusiness = false,
    this.isGovernment = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = isBusiness
        ? "Apply for Gold Badge"
        : (isGovernment ? "Apply for Gray Badge" : "Apply for Blue Badge");
        
    final iconColor = isBusiness
        ? const Color(0xFFF59E0B) // Gold
        : (isGovernment ? const Color(0xFF64748B) : const Color(0xFF0095F6)); // Gray : Blue

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titleText,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.verified_rounded,
          color: iconColor,
          size: 20,
        ),
      ],
    );
  }
}
