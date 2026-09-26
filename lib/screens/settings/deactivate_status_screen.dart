// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../auth/auth_screen.dart';

class DeactivateStatusScreen extends StatefulWidget {
  final String username;
  const DeactivateStatusScreen({super.key, required this.username});

  @override
  State<DeactivateStatusScreen> createState() => _DeactivateStatusScreenState();
}

class _DeactivateStatusScreenState extends State<DeactivateStatusScreen> {
  int _selectedOption = 0; // 0 for safe harbor, 1 for wipe
  late final String _confirmationId;
  late final DateTime _purgeDate;

  @override
  void initState() {
    super.initState();
    _purgeDate = DateTime.now().add(const Duration(days: 30));
    _confirmationId = 'PIG-${Random().nextInt(9000) + 1000}-DEACT-${DateTime.now().year % 100}';
  }

  void _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    // If they selected permanent wipe, trigger it before logging out
    if (_selectedOption == 1) {
      // In a real scenario, this might need another confirmation or password check,
      // but following the user's prompt to "build UI and not full logic for now".
      // We'll just do the logout since deactivation is already done.
    }
    
    await authService.handleSignout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthScreen(onLoginSuccess: () {})),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProfile = context.select((DatabaseService db) => db.myProfile);
    final fullName = myProfile?.fullName ?? 'User';
    final firstName = fullName.split(' ').first;
    final avatarUrl = myProfile?.avatarUrl;
    final dateFormatted = DateFormat('MMMM d, yyyy').format(_purgeDate);
    final dateFormattedShort = DateFormat('EEEE, MMM d, yyyy - HH:mm').format(_purgeDate);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context), // Typically blocked in real app after deactivation
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_rounded, color: context.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Deactivate Account',
              style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Icon(Icons.settings_outlined, color: context.textPrimary, size: 22),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 12,
            backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person, size: 16, color: context.textSecondary) : null,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // Top Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border),
              ),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.security, color: context.textPrimary, size: 32),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock, size: 14, color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.transparent,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person, size: 10, color: context.textSecondary) : null,
                        ),
                        const SizedBox(width: 8),
                        Text('$firstName (@${widget.username})', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account has been deactivated',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'re sorry to see you go, $firstName. Your public profile, publications, mentions, and interactions are immediately hidden from the platform.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildBadge(context, Icons.visibility_off_outlined, 'Stream Hidden'),
                      _buildBadge(context, Icons.notifications_off_outlined, 'Pings Muted'),
                      _buildBadge(context, Icons.verified_user_outlined, 'Vault Safe'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Radio Buttons Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline, size: 20, color: context.textPrimary),
                      const SizedBox(width: 8),
                      Text('30-DAY SAFE HARBOR', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: context.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Countdown Active', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Option 1
                  GestureDetector(
                    onTap: () => setState(() => _selectedOption = 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<int>(
                          value: 0,
                          groupValue: _selectedOption,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedOption = val);
                          },
                          activeColor: context.textPrimary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('30-Day Recovery Period', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                                  const SizedBox(width: 8),
                                  Text('Until ${DateFormat('MMM d, yyyy').format(_purgeDate)}', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.5),
                                  children: [
                                    const TextSpan(text: 'If you change your mind, simply sign in with your handle and password before '),
                                    TextSpan(text: dateFormatted, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
                                    const TextSpan(text: ' to instantly restore your posts, threads, and bookmarks intact.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option 2
                  GestureDetector(
                    onTap: () => setState(() => _selectedOption = 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: _selectedOption,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedOption = val);
                          },
                          activeColor: context.textPrimary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Permanent Server Wipe', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                                  const SizedBox(width: 8),
                                  Text('Irreversible', style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'After 30 days have elapsed, all encryption keys, personal archives, linked credentials, and telemetry will be permanently wiped from our clustered storage.',
                                style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: context.border, height: 1),
                  const SizedBox(height: 16),
                  
                  // Purge Date Footer
                  Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 20, color: context.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Automatic Purge Date', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                            Text(dateFormattedShort, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border, size: 14, color: context.textSecondary),
                            const SizedBox(width: 6),
                            Text('Save Note', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Survey Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_border_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text('Help Us Refine Pigeon', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text('1-min Survey', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_outward_rounded, size: 12, color: context.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Want to tell us why you\'re taking time away?', style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSurveyButton(context, Icons.eco, 'Taking Break', Colors.green),
                      _buildSurveyButton(context, Icons.settings, 'Usability', Colors.blue),
                      _buildSurveyButton(context, Icons.lock, 'Privacy', Colors.orange),
                      _buildSurveyButton(context, Icons.auto_awesome, 'Other', Colors.yellow),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text('Log Out & Exit Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _handleLogout,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text('Need help? Contact Pigeon Support', style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirmation ID: $_confirmationId',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'A confirmation dispatch has been sent to your primary recovery address.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSurveyButton(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
      ],
    );
  }
}
