import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/screens/profile/profile_screen.dart';
import 'package:dak/utils/app_theme.dart';
import '../../../widgets/verification_badge.dart';

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
    final primaryColor = context.textPrimary; // Corporate vibe: dark/light text color instead of brand green where possible

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            children: [
              // Top Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── 1. Hero Avatar (Professional, no gradients) ──
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: context.border,
                            backgroundImage: widget.otherUser.avatarUrl != null &&
                                    widget.otherUser.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.otherUser.avatarUrl!)
                                : null,
                            child: (widget.otherUser.avatarUrl == null ||
                                    widget.otherUser.avatarUrl!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: context.textMuted,
                                  )
                                : null,
                          ),
                          // Online Indicator Dot
                          if (isOnline)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981), // Solid green for online
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF111827) : Colors.white,
                                    width: 3,
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
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.otherUser.isVerified) ...[
                            const SizedBox(width: 6),
                            VerificationBadge(
                              isVerified: true,
                              badgeType: widget.otherUser.badgeType,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Username Handle
                      Text(
                        '@${widget.otherUser.username}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status Text
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOnline)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isOnline
                                  ? const Color(0xFF10B981)
                                  : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── 3. Bio & Followers (Corporate minimal style) ──
                      if (widget.otherUser.bio != null &&
                          widget.otherUser.bio!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.otherUser.bio!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: context.textPrimary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.otherUser.followersCount > 0 ||
                          widget.otherUser.followingCount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              context,
                              _formatCount(widget.otherUser.followersCount),
                              'Followers',
                            ),
                            Container(
                              height: 14,
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              color: context.border,
                            ),
                            _buildStatItem(
                              context,
                              _formatCount(widget.otherUser.followingCount),
                              'Following',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── 4. Action Buttons (Profile, Mute, Theme, Media) ──
                      // Professional solid/outlined buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildCorporateActionButton(
                              context: context,
                              icon: Icons.person_outline,
                              label: 'Profile',
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCorporateActionButton(
                              context: context,
                              icon: _muted
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_outlined,
                              label: _muted ? 'Unmute' : 'Mute',
                              isOutlined: false,
                              onTap: () {
                                final newState = !_muted;
                                setState(() => _muted = newState);
                                widget.onToggleMute(newState);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── 5. Options (List style, very professional) ──
                      _buildSectionHeader(context, 'Chat Options'),
                      _buildCorporateListTile(
                        context: context,
                        icon: Icons.palette_outlined,
                        title: 'Theme & Wallpaper',
                        onTap: () {
                          Navigator.pop(context);
                          widget.onChangeTheme();
                        },
                      ),
                      Divider(height: 1, color: context.border),
                      _buildCorporateListTile(
                        context: context,
                        icon: Icons.notifications_none_outlined,
                        title: 'Mute Notifications',
                        trailing: Switch.adaptive(
                          value: _muted,
                          activeTrackColor: primaryColor,
                          onChanged: (value) {
                            setState(() => _muted = value);
                            widget.onToggleMute(value);
                          },
                        ),
                        onTap: () {
                          final newState = !_muted;
                          setState(() => _muted = newState);
                          widget.onToggleMute(newState);
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Privacy'),
                      _buildCorporateListTile(
                        context: context,
                        icon: Icons.block_outlined,
                        title: 'Block User',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onBlockUser();
                        },
                      ),
                      Divider(height: 1, color: context.border),
                      _buildCorporateListTile(
                        context: context,
                        icon: Icons.delete_outline,
                        title: 'Delete Conversation',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDeleteConversation();
                        },
                      ),

                      // ── 6. Shared Media Section ──
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(context, 'Shared Media'),
                          if (widget.sharedMedia.isNotEmpty)
                            Text(
                              '${widget.sharedMedia.length}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (widget.sharedMedia.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 24,
                                color: context.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No media shared',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.textMuted,
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
                            crossAxisCount: 4,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: widget.sharedMedia.length,
                          itemBuilder: (context, index) {
                            final mediaUrl = widget.sharedMedia[index]
                                ['media_url'] as String;
                            return GestureDetector(
                              onTap: () => widget.onMediaTapped(mediaUrl),
                              child: Container(
                                color: context.border,
                                child: CachedNetworkImage(
                                  imageUrl: mediaUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, url) => const SizedBox(),
                                  errorWidget: (ctx, url, err) => Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 16,
                                      color: context.textMuted,
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

  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCorporateActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOutlined = true,
  }) {
    final isDark = context.isDarkMode;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6); // subtle gray

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: primaryTextColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: context.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: primaryTextColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildCorporateListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? const Color(0xFFDC2626) : context.textPrimary;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
