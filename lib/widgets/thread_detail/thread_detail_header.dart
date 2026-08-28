import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/routes.dart';
import '../../screens/profile/profile_screen.dart';
import '../verification_badge.dart';

class ThreadDetailHeader extends StatelessWidget {
  final ThreadPost activePost;
  final DatabaseService dbService;
  final VoidCallback onMoreTap;
  final String Function(String) formatTime;
  final String Function(int) formatCount;

  const ThreadDetailHeader({
    super.key,
    required this.activePost,
    required this.dbService,
    required this.onMoreTap,
    required this.formatTime,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[900],
            backgroundImage: activePost.isAnonymous
                ? const AssetImage('assets/anonymous_avatar.png') as ImageProvider
                : ((activePost.author.avatarUrl != null && activePost.author.avatarUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(activePost.author.avatarUrl!)
                    : null),
            child: (!activePost.isAnonymous && (activePost.author.avatarUrl == null || activePost.author.avatarUrl!.isEmpty))
                ? const Icon(Icons.person, size: 24, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activePost.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.pin_fill,
                          size: 12,
                          color: context.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pinned post',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: activePost.isAnonymous
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  NoTransitionPageRoute(
                                    child: ProfileScreen(userId: activePost.userId),
                                  ),
                                );
                              },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                activePost.author.fullName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.hindSiliguri(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            if (!activePost.isAnonymous && activePost.author.isVerified) ...[
                              const SizedBox(width: 4),
                              VerificationBadge(
                                isVerified: true,
                                badgeType: activePost.author.badgeType,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!activePost.isAnonymous && activePost.userId != dbService.currentUid) ...[
                      const SizedBox(width: 8),
                      _buildFollowButton(context),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      "· ${formatTime(activePost.createdAt)}",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "@${activePost.author.username}",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "·",
                      style: TextStyle(color: context.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 13,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${formatCount(activePost.viewsCount)} views",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onMoreTap,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.more_horiz, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    final isFollowing = dbService.isFollowingUser(activePost.userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => dbService.toggleFollowUser(activePost.userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isFollowing
              ? Colors.transparent
              : (isDark ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isFollowing
                ? (isDark ? Colors.white24 : Colors.black12)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isFollowing
                ? context.textPrimary
                : (isDark ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }
}
