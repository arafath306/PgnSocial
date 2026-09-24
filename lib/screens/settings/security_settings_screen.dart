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
      if (!mounted) return;
      final provider = Provider.of<GeneralSettingsProvider>(context, listen: false);
      provider.fetchActiveSessions();
      provider.startListeningToSessions();
    });
  }

  @override
  void dispose() {
    Provider.of<GeneralSettingsProvider>(context, listen: false).stopListeningToSessions();
    super.dispose();
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
          final otherSessions = sessions.where((s) => s['status'] != 'Active now').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader(context, 'Login Protection'),
              const TwoFactorOption(),
              const ChangePasswordOption(),
              const ChangeEmailOption(),
              const SizedBox(height: 16),

              // Active Sessions Section Header with "Log out others" button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE SESSIONS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (otherSessions.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _confirmRevokeAllOthers(context, provider),
                        child: Text(
                          'Log out others',
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (provider.isLoadingSessions && sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (sessions.isEmpty)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Center(
                        child: Text(
                          'No active sessions found.',
                          style: GoogleFonts.inter(color: context.textMuted, fontSize: 13.5),
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 0.5, color: context.border),
                  ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
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
        Divider(height: 1, thickness: 0.5, color: context.border),
      ],
    );
  }

  Widget _buildSessionTile(BuildContext context, GeneralSettingsProvider provider, Map<String, String> session) {
    final isCurrent = session['status'] == 'Active now';
    final deviceName = session['device'] ?? 'Unknown Device';
    final osVersion = session['os_version'] ?? '';
    final location = session['location'] ?? 'Unknown Location';
    final ip = session['ip'] ?? '';
    final status = session['status'] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDeviceIcon(session),
                  color: isCurrent ? context.primaryAccent : context.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'This device',
                                  style: GoogleFonts.inter(
                                    color: context.primaryAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        location,
                        if (osVersion.isNotEmpty && !deviceName.contains(osVersion)) osVersion,
                        status,
                      ].join('  ·  '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                    if (ip.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'IP: $ip',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textMuted.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isCurrent)
                TextButton(
                  onPressed: () => _confirmRevokeSession(context, provider, session),
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
        ),
        Divider(height: 1, thickness: 0.5, color: context.border),
      ],
    );
  }

  IconData _getDeviceIcon(Map<String, String> session) {
    final type = (session['device_type'] ?? '').toLowerCase();
    final device = (session['device'] ?? '').toLowerCase();

    if (type == 'tablet' || device.contains('ipad') || device.contains('tablet') || device.contains('tab')) {
      return Icons.tablet_android_rounded;
    }
    if (type == 'desktop' ||
        device.contains('mac') ||
        device.contains('windows') ||
        device.contains('pc') ||
        device.contains('linux')) {
      return Icons.laptop_chromebook_rounded;
    }
    if (type == 'web' ||
        device.contains('web') ||
        device.contains('browser') ||
        device.contains('chrome') ||
        device.contains('safari') ||
        device.contains('firefox')) {
      return Icons.language_rounded;
    }
    if (device.contains('iphone') || device.contains('ios')) {
      return Icons.phone_iphone_rounded;
    }
    return Icons.phone_android_rounded;
  }

  void _confirmRevokeSession(
    BuildContext context,
    GeneralSettingsProvider provider,
    Map<String, String> session,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text(
          'Log out session?',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Are you sure you want to log out from "${session['device']}"? That device will need to sign in again.',
          style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              provider.revokeSession(session['id']!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session revoked: ${session['device']}'),
                  backgroundColor: context.primaryAccent,
                ),
              );
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeAllOthers(
    BuildContext context,
    GeneralSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text(
          'Log out of other devices?',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          'This will revoke all active sessions except this current device. You will stay signed in on this device only.',
          style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              provider.revokeAllOtherSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All other sessions revoked successfully'),
                  backgroundColor: context.primaryAccent,
                ),
              );
            },
            child: Text(
              'Log Out Others',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
