import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../screens/settings/two_factor_setup_screen.dart';

class TwoFactorOption extends StatefulWidget {
  const TwoFactorOption({super.key});

  @override
  State<TwoFactorOption> createState() => _TwoFactorOptionState();
}

class _TwoFactorOptionState extends State<TwoFactorOption> {
  bool _is2faEnabled = false;
  sb.Factor? _enrolledFactor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load2faStatus();
    });
  }

  Future<void> _load2faStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final factor = await authService.getEnrolledFactor();
    if (mounted) {
      setState(() {
        _enrolledFactor = factor;
        _is2faEnabled = factor != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Two-Factor Authentication (2FA)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _is2faEnabled
                      ? '2FA is currently enabled for this account.'
                      : 'Secure your account by requiring a code during login.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _is2faEnabled,
            onChanged: (val) async {
              if (val) {
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()),
                );
                if (success == true) {
                  _load2faStatus();
                }
              } else {
                if (_enrolledFactor != null) {
                  // Prompt for confirmation
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.cardBg,
                      title: Text(
                        'Disable 2FA?',
                        style: GoogleFonts.inter(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to disable Two-Factor Authentication? Your account will be less secure.',
                        style: GoogleFonts.inter(color: context.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Disable', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!context.mounted) return;
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.unenrollMfa(_enrolledFactor!.id);
                    _load2faStatus();
                  }
                }
              }
            },
            activeThumbColor: Colors.white,
            activeTrackColor: context.primaryAccent,
            inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors.black12,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
