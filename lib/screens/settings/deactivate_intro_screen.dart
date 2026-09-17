import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import 'deactivate_confirm_screen.dart';
import 'whats_coming_screen.dart';

class DeactivateIntroScreen extends StatefulWidget {
  const DeactivateIntroScreen({super.key});

  @override
  State<DeactivateIntroScreen> createState() => _DeactivateIntroScreenState();
}

class _DeactivateIntroScreenState extends State<DeactivateIntroScreen> {
  bool _isUnderstood = false;

  @override
  Widget build(BuildContext context) {
    final myProfile = context.select((DatabaseService db) => db.myProfile);
    final username = myProfile?.username ?? 'user';
    final fullName = myProfile?.fullName ?? 'User';
    final avatarUrl = myProfile?.avatarUrl;
    final coverUrl = myProfile?.coverUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Darkest background matching image
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_rounded, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text(
              'Deactivate Account',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Icon(Icons.settings_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[900],
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person, size: 16, color: Colors.grey[400]) : null,
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
            // Warning Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: context.primaryAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will deactivate your account',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please review what happens when you step away from Pigeon.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400], height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Card with Background Image
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: coverUrl != null && coverUrl.isNotEmpty
                          ? CachedNetworkImageProvider(coverUrl) as ImageProvider
                          : const AssetImage('assets/images/abstract_bg.png'),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        opacity: 0.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 32) : null,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ACTIVE ACCOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (myProfile?.isVerified == true) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, color: Colors.grey[400], size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'You\'re about to start the process of deactivating your Pigeon account. Your display name, @$username, and public profile will no longer be viewable on pigeon.social, iOS, or Android.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Temporary Pause details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'TEMPORARY PAUSE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Icon(Icons.pause_circle_outline, color: Colors.white, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deactivation Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your profile, threads, likes, and followers will be temporarily hidden immediately. All data remains securely preserved, and you can reactivate anytime within 30 days simply by logging back into your account.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Reversible within 30-day grace period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 24),
            Text(
              'WHAT ELSE YOU SHOULD KNOW',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),

            // Info Items List
            Column(
              children: [
                  _buildInfoItem(
                    icon: Icons.history_rounded,
                    title: '30-day grace period',
                    description: 'You can restore your account if it was accidentally or wrongfully deactivated for up to 30 days after deactivation.',
                  ),
                  _buildInfoItem(
                    icon: Icons.public_rounded,
                    title: 'Search visibility',
                    description: 'Some account information may still be temporarily available in search engines like Google, DuckDuckGo, or Bing.',
                  ),
                  _buildInfoItem(
                    icon: Icons.alternate_email_rounded,
                    title: 'Need a fresh start instead?',
                    description: 'If you just want to change your @handle or associated email address, you don\'t need to deactivate. You can update them anytime in Settings.',
                  ),
                  _buildInfoItem(
                    icon: Icons.archive_outlined,
                    title: 'Save your memories',
                    description: 'Download your complete personal archive and data export before proceeding with deactivation.',
                    isLast: true,
                    bottomWidget: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Request Archive (.zip)', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[300])),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey[300]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Permanently Erase Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.delete_forever_outlined, color: context.primaryAccent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Looking to permanently erase everything?',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Permanent deletion purges all posts, media, and releases your handle immediately without a 30-day grace period.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Account Deletion System is coming soon in the next update!'),
                          action: SnackBarAction(
                            label: "View Roadmap",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WhatsComingScreen()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Delete account instead (Coming Soon)',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: context.primaryAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: context.primaryAccent, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isUnderstood,
                    onChanged: (val) {
                      setState(() => _isUnderstood = val ?? false);
                    },
                    activeColor: context.primaryAccent,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isUnderstood = !_isUnderstood),
                    child: Text(
                      'I understand my posts, threads, and interactions will be hidden immediately.',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[300], height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent, // Slightly darker reddish brown
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                icon: const Icon(Icons.person_off_outlined, size: 20),
                label: Text(
                  'Deactivate @$username',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: _isUnderstood
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DeactivateConfirmScreen(username: username)),
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel • Keep Account',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
    Widget? bottomWidget,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 16 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400], height: 1.5)),
                ?bottomWidget,
                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
