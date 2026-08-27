import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_legal_terms.dart';
import '../../utils/routes.dart';
import '../../screens/create_thread_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/beta_center_screen.dart';
import '../../screens/saved_posts_screen.dart';
import '../../screens/communities/community_home_screen.dart';
import '../verification_badge.dart';

/// Full drawer / desktop left-sidebar navigation panel.
///
/// Works both as a mobile [Drawer] child (set [isDesktop] = false) and as
/// a persistent desktop sidebar (set [isDesktop] = true).
/// All tab switches are delegated to [onTabChanged]; internal navigation
/// (push to Settings, Community, etc.) is handled inside this widget.
class MainDrawer extends StatelessWidget {
  final int currentIndex;
  final Profile? myProfile;
  final bool isDesktop;
  final int unreadMessagesCount;
  final int unreadNotificationsCount;
  final void Function(int) onTabChanged;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.myProfile,
    required this.isDesktop,
    required this.unreadMessagesCount,
    required this.unreadNotificationsCount,
    required this.onTabChanged,
  });

  // ── Private helpers ──────────────────────────────────────────────────────

  void _closeIfMobile(BuildContext context) {
    if (!isDesktop) Navigator.pop(context);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Help & Support",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          "Need help? Contact our support team at support@dak.social or check our online documentation.",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showModal(BuildContext context, String title, String contentText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Text(
                    contentText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Accept",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 20.0, right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _closeIfMobile(context);
              onTabChanged(4);
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              backgroundImage: myProfile?.avatarUrl != null &&
                      myProfile!.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(myProfile!.avatarUrl!)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _closeIfMobile(context);
              onTabChanged(4);
            },
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    myProfile?.fullName ?? "Arafath",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (myProfile?.isVerified == true) ...[
                  const SizedBox(width: 4),
                  VerificationBadge(
                    isVerified: true,
                    badgeType: myProfile?.badgeType,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "@${myProfile?.username ?? 'arafath306'}",
            style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
              children: [
                TextSpan(
                  text: '${myProfile?.followersCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'followers  ·  '),
                TextSpan(
                  text: '${myProfile?.followingCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      minLeadingWidth: 28,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E824C) : context.textPrimary,
            size: 26,
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  "$badgeCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFF1E824C) : context.textPrimary,
          letterSpacing: -0.1,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Terms of Service",
              AppLegalTerms.termsOfService,
            ),
            child: Text(
              "Terms of Service",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Privacy Policy",
              AppLegalTerms.privacyPolicy,
            ),
            child: Text(
              "Privacy Policy",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _closeIfMobile(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BetaCenterScreen()),
                );
              },
              icon: Icon(Icons.bug_report_outlined, size: 16, color: context.textPrimary),
              label: Text(
                "Beta Center",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode
                    ? const Color(0xFF121422)
                    : const Color(0xFFF3F4F6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showHelpDialog(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.border, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text(
                "Help",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.search,
                    title: "Explore",
                    isActive: currentIndex == 1,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(1);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 0
                        ? CupertinoIcons.house_fill
                        : CupertinoIcons.house,
                    title: "Home",
                    isActive: currentIndex == 0,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 2
                        ? CupertinoIcons.ellipses_bubble_fill
                        : CupertinoIcons.ellipses_bubble,
                    title: "Chat",
                    isActive: currentIndex == 2,
                    badgeCount: unreadMessagesCount,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(2);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 3
                        ? CupertinoIcons.bell_fill
                        : CupertinoIcons.bell,
                    title: "Notifications",
                    isActive: currentIndex == 3,
                    badgeCount: unreadNotificationsCount,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(3);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.tag,
                    title: "Feeds",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.groups_rounded,
                    title: "Community",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const CommunityHomeScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.bookmark,
                    title: "Saved",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const SavedPostsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 4
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.person,
                    title: "Profile",
                    isActive: currentIndex == 4,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(4);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.settings,
                    title: "Settings",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: SettingsScreen(
                            onSwitchToProfile: () => onTabChanged(4),
                          ),
                        ),
                      );
                    },
                  ),
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateThreadScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Text(
                            "Post",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
          Divider(height: 1, color: context.border),
          _buildFooterLinks(context),
          _buildFooterButtons(context),
        ],
      ),
    );
  }
}
