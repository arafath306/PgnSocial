import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../screens/settings/change_email_screen.dart';

class ChangeEmailOption extends StatelessWidget {
  const ChangeEmailOption({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(
            'Change Email',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            'Update your registered email address.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: context.textMuted,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
            );
          },
        ),
        Divider(height: 1, thickness: 0.5, color: context.border),
      ],
    );
  }
}
