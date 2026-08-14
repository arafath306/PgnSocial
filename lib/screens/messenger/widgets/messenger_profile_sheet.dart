import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/screens/profile/profile_screen.dart';
import 'package:dak/utils/app_theme.dart';

class MessengerProfileSheet extends StatefulWidget {
  final Profile otherUser;
  final bool isMuted;
  final List<Map<String, dynamic>> sharedMedia;
  final ValueChanged<bool> onToggleMute;
  final VoidCallback onChangeTheme;
  final VoidCallback onBlockUser;
  final VoidCallback onDeleteConversation;
  final ValueChanged<String> onMediaTapped;

  const MessengerProfileSheet({
    super.key,
    required this.otherUser,
    required this.isMuted,
    required this.sharedMedia,
    required this.onToggleMute,
    required this.onChangeTheme,
    required this.onBlockUser,
    required this.onDeleteConversation,
    required this.onMediaTapped,
  });

  @override
  State<MessengerProfileSheet> createState() => _MessengerProfileSheetState();
}

class _MessengerProfileSheetState extends State<MessengerProfileSheet> {
  late bool _muted;

  @override
  void initState() {
    super.initState();
    _muted = widget.isMuted;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _getStatusText() {
    if (!widget.otherUser.isActiveStatusEnabled) {
      return 'Offline';
    }
    if (widget.otherUser.lastSeen != null) {
      final diff = DateTime.now().difference(widget.otherUser.lastSeen!);
      if (diff.inMinutes <= 5) {
        return 'Active now';
      } else if (diff.inMinutes < 60) {
        return 'Active ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Active ${diff.inHours}h ago';
      } else {
        return 'Active ${diff.inDays}d ago';
      }
    }
    return 'Offline';
  }

  bool _isUserOnline() {
    return widget.otherUser.isActiveStatusEnabled &&
        widget.otherUser.lastSeen != null &&
        DateTime.now().difference(widget.otherUser.lastSeen!).inMinutes <= 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isOnline = _isUserOnline();
    final statusText = _getStatusText();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C101D) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                spreadRadius: 4,
              )
            ],
          ),
          child: Column(
            children: [
              // Top Drag Handle & Close Bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── 1. Hero Avatar with Glowing Ring & Online Indicator ──
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Ambient Glow
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  context.primaryAccent.withValues(alpha: 0.6),
                                  const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Inner Avatar
                          CircleAvatar(
                            radius: 49,
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            backgroundImage: widget.otherUser.avatarUrl != null &&
                                    widget.otherUser.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.otherUser.avatarUrl!)
                                : null,
                            child: (widget.otherUser.avatarUrl == null ||
                                    widget.otherUser.avatarUrl!.isEmpty)
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: context.textMuted,
                                  )
                                : null,
                          ),
                          // Live Online Indicator Dot
                          if (isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF0C101D)
                                        : Colors.white,
                                    width: 3.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 2. User Name & Verified Badge ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.otherUser.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.otherUser.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF3B82F6),
                              size: 19,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Username Handle
                      Text(
                        '@${widget.otherUser.username}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : context.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── 3. Quick Action Bar (2026 4-Pill Hub) ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF151C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: context.border.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 👤 Profile Action
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.person_rounded,
                              label: 'Profile',
                              color: const Color(0xFF3B82F6),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                        userId: widget.otherUser.id),
                                  ),
                                );
                              },
                            ),
                            // 🔔 Mute Action
                            _buildQuickActionButton(
                              context: context,
                              icon: _muted
                                  ? Icons.notifications_off_rounded
                                  : Icons.notifications_rounded,
                              label: _muted ? 'Unmute' : 'Mute',
                              color: _muted
                                  ? const Color(0xFFF59E0B)
                                  : context.primaryAccent,
                              onTap: () {
                                final newState = !_muted;
                                setState(() => _muted = newState);
                                widget.onToggleMute(newState);
                              },
                            ),
                            // 🎨 Theme Action
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.palette_rounded,
                              label: 'Theme',
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onChangeTheme();
                              },
                            ),
                            // 🖼️ Media Action
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.photo_library_rounded,
                              label: 'Media',
                              color: const Color(0xFFEC4899),
                              badgeCount: widget.sharedMedia.length,
                              onTap: () {
                                if (widget.sharedMedia.isNotEmpty) {
                                  widget.onMediaTapped(
                                      widget.sharedMedia.first['media_url']
                                          as String);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No photos or videos shared yet.',
                                        style: GoogleFonts.inter(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 4. Bio & Social Followers Pill (if present) ──
                      if ((widget.otherUser.bio != null &&
                              widget.otherUser.bio!.isNotEmpty) ||
                          widget.otherUser.followersCount > 0 ||
                          widget.otherUser.followingCount > 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151C2C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: context.border.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bio text
                              if (widget.otherUser.bio != null &&
                                  widget.otherUser.bio!.isNotEmpty) ...[
                                Text(
                                  widget.otherUser.bio!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: context.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  color: context.border.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Followers / Following row
                              Row(
                                children: [
                                  _buildStatItem(
                                    context,
                                    _formatCount(
                                        widget.otherUser.followersCount),
                                    'Followers',
                                  ),
                                  Container(
                                    height: 16,
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    color:
                                        context.border.withValues(alpha: 0.6),
                                  ),
                                  _buildStatItem(
                                    context,
                                    _formatCount(
                                        widget.otherUser.followingCount),
                                    'Following',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── 5. Grouped Settings Section ──
                      _buildSectionHeader(context, 'Chat Settings & Theme'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF151C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: context.border.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              context: context,
                              icon: Icons.color_lens_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              title: 'Chat Theme & Wallpaper',
                              subtitle: 'Change colors, gradients & wallpaper',
                              onTap: () {
                                Navigator.pop(context);
                                widget.onChangeTheme();
                              },
                            ),
                            Divider(
                              height: 1,
                              indent: 56,
                              color: context.border.withValues(alpha: 0.4),
                            ),
                            _buildSettingsTile(
                              context: context,
                              icon: Icons.notifications_active_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              title: 'Mute Notifications',
                              subtitle: 'Silence alerts for this conversation',
                              trailing: Switch.adaptive(
                                value: _muted,
                                activeTrackColor: context.primaryAccent,
                                onChanged: (value) {
                                  setState(() => _muted = value);
                                  widget.onToggleMute(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 6. Privacy & Safety Group ──
                      _buildSectionHeader(context, 'Privacy & Actions'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF151C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: context.border.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              context: context,
                              icon: Icons.block_rounded,
                              iconColor: const Color(0xFFEF4444),
                              title: 'Block @${widget.otherUser.username}',
                              subtitle: 'Prevent them from sending you messages',
                              isDestructive: true,
                              onTap: () {
                                Navigator.pop(context);
                                widget.onBlockUser();
                              },
                            ),
                            Divider(
                              height: 1,
                              indent: 56,
                              color: context.border.withValues(alpha: 0.4),
                            ),
                            _buildSettingsTile(
                              context: context,
                              icon: Icons.delete_outline_rounded,
                              iconColor: const Color(0xFFEF4444),
                              title: 'Delete Conversation',
                              subtitle: 'Permanently remove chat history',
                              isDestructive: true,
                              onTap: () {
                                Navigator.pop(context);
                                widget.onDeleteConversation();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 7. Shared Media Section ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(context, 'Shared Media'),
                          if (widget.sharedMedia.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.primaryAccent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${widget.sharedMedia.length} files',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (widget.sharedMedia.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151C2C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.border.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 32,
                                color: context.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No media shared yet',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: context.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: widget.sharedMedia.length,
                          itemBuilder: (context, index) {
                            final mediaUrl = widget.sharedMedia[index]
                                ['media_url'] as String;
                            return GestureDetector(
                              onTap: () => widget.onMediaTapped(mediaUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                  child: CachedNetworkImage(
                                    imageUrl: mediaUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.primaryAccent,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (ctx, url, err) => Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        size: 24,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helper Widgets ──

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: context.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final isDark = context.isDarkMode;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFEF4444) : context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: context.textMuted,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: context.textMuted.withValues(alpha: 0.6),
            size: 20,
          ),
    );
  }
}
