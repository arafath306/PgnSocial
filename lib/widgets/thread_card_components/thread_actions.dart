import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../services/sound_service.dart';
import '../../utils/app_theme.dart';

class ThreadActions extends StatelessWidget {
  final ThreadPost post;
  final DatabaseService dbService;
  final VoidCallback onShowComments;
  final VoidCallback onShowRepostOptions;
  final VoidCallback onShare;

  const ThreadActions({
    super.key,
    required this.post,
    required this.dbService,
    required this.onShowComments,
    required this.onShowRepostOptions,
    required this.onShare,
  });

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    if (count < 1000000000) return '${(count / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    return '${(count / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}B';
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            child: Icon(icon, color: color, size: 19),
          ),
          if (count > 0) ...[
            const SizedBox(width: 2),
            Text(
              _formatCount(count),
              style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary.withValues(alpha: 0.75)),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetPost = post.isRepost && post.repostedPost != null ? post.repostedPost! : post;
    final isLiked = targetPost.isLikedByMe;
    final isSaved = dbService.isSaved(targetPost.id);
    final isReposted = dbService.isReposted(targetPost.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          context: context,
          icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          color: isLiked ? Colors.red : context.textPrimary,
          isActive: isLiked,
          count: targetPost.likesCount,
          onTap: () {
            HapticFeedback.lightImpact();
            if (!isLiked) {
              SoundService.playLike();
            }
            dbService.toggleLike(targetPost.id, !isLiked);
          },
        ),
        _buildActionItem(
          context: context,
          icon: CupertinoIcons.chat_bubble,
          color: context.textPrimary,
          isActive: false,
          count: targetPost.repliesCount,
          onTap: onShowComments,
        ),
        _buildActionItem(
          context: context,
          icon: CupertinoIcons.arrow_2_circlepath,
          color: isReposted ? const Color(0xFF1E824C) : context.textPrimary,
          isActive: isReposted,
          count: targetPost.repostsCount,
          onTap: onShowRepostOptions,
        ),
        _buildActionItem(
          context: context,
          icon: CupertinoIcons.chart_bar_alt_fill,
          color: context.textPrimary,
          isActive: false,
          count: targetPost.viewsCount,
          onTap: () {}, // Views don't have an action on tap for now
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              context: context,
              icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
              color: isSaved ? const Color(0xFF1E824C) : context.textPrimary,
              isActive: isSaved,
              count: targetPost.savesCount,
              onTap: () {
                dbService.toggleSaveThread(targetPost.id);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSaved ? "Removed from bookmarks" : "Post saved to bookmarks",
                      style: GoogleFonts.inter(),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: isSaved ? Colors.grey[700] : const Color(0xFF1E824C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildActionItem(
              context: context,
              icon: CupertinoIcons.arrowshape_turn_up_right,
              color: context.textPrimary,
              isActive: false,
              count: targetPost.sharesCount,
              onTap: onShare,
            ),
          ],
        ),
      ],
    );
  }
}
