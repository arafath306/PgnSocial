import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import 'deactivate_intro_screen.dart';
import '../../widgets/settings/change_email_option.dart';
import '../../widgets/settings/change_password_option.dart';
import '../../widgets/settings/two_factor_option.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeneralSettingsProvider>(context, listen: false).fetchActiveSessions();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          final sessions = provider.activeSessions;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader(context, 'Login Protection'),
              const TwoFactorOption(),
              const ChangePasswordOption(),
              const ChangeEmailOption(),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Active Sessions'),
              if (sessions.isEmpty)
                Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'No other active sessions found.',
                    style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                  ),
                )
              else
                ...sessions.map((session) => _buildSessionTile(context, provider, session)),
                
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Account Management'),
              _buildActionTile(
                context,
                title: 'Deactivate or Delete Account',
                subtitle: 'Manage your account presence and data.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeactivateIntroScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }



  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: context.textMuted,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, GeneralSettingsProvider provider, Map<String, String> session) {
    final isCurrent = session['status'] == 'Active now';
    return Container(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            session['device']!.contains('iPhone') || session['device']!.contains('Pixel')
                ? Icons.phone_android_rounded
                : Icons.computer_rounded,
            color: context.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      session['device']!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: context.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF0C2517) : const Color(0x1A1E824C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.inter(
                            color: context.primaryAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['location']}  ·  ${session['status']}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () {
                provider.revokeSession(session['id']!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session revoked: ${session['device']}'),
                    backgroundColor: context.primaryAccent,
                  ),
                );
              },
              child: Text(
                'Revoke',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
