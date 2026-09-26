import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class PigeonPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  const PigeonPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: outlined ? context.primaryAccent : Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: outlined ? context.primaryAccent : Colors.white,
            ),
          ),
        ],
      ],
    );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.primaryAccent, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: disabled
              ? null
              : LinearGradient(
                  colors: [context.primaryAccent, context.primaryAccent.withValues(alpha: 0.8)],
                ),
          color: disabled ? context.border : null,
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
