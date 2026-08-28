import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../services/sound_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/routes.dart';
import '../../screens/create_thread_screen.dart';
import '../poll_widget.dart';
import '../voice_post_player.dart';
import 'nested_original_post.dart';
import 'thread_detail_music_player.dart';

class ThreadDetailBody extends StatelessWidget {
  final ThreadPost activePost;
  final DatabaseService dbService;
  final int commentsCount;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final String Function(int) formatCount;

  const ThreadDetailBody({
    super.key,
    required this.activePost,
    required this.dbService,
    required this.commentsCount,
    required this.onCommentTap,
    required this.onShareTap,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activePost.content,
            style: GoogleFonts.hindSiliguri(
              fontSize: 17.5,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          if (activePost.isRepost && activePost.repostedPost != null)
            NestedOriginalPost(
                origPost: activePost.repostedPost!, dbService: dbService),
          if (activePost.imageUrls != null && activePost.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            MusicImageStack(
              imageUrls: activePost.imageUrls!,
              height: 220,
              musicTrack: activePost.musicTrack,
              postId: activePost.id,
            ),
          ],
          if (activePost.audioUrl != null && activePost.audioUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            VoicePostPlayer(audioUrl: activePost.audioUrl!),
          ],
          PollWidget(post: activePost, dbService: dbService),
          

          
          Divider(height: 24, color: context.border),

          // Action buttons with inline counts and Save post
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like Button (React)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (!activePost.isLikedByMe) {
                    SoundService.playLike();
                  }
                  dbService.toggleLike(activePost.id, !activePost.isLikedByMe);
                },
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: activePost.isLikedByMe
                          ? const Icon(
                              CupertinoIcons.heart_fill,
                              key: ValueKey<int>(1),
                              color: Colors.red,
                              size: 18,
                            )
                          : Icon(
                              CupertinoIcons.heart,
                              key: const ValueKey<int>(0),
                              color: context.textPrimary.withValues(alpha: 0.75),
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatCount(activePost.likesCount),
                      style: TextStyle(
                        color: activePost.isLikedByMe
                            ? Colors.red
                            : context.textPrimary.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Comment Button
              _buildActionButton(
                context: context,
                icon: CupertinoIcons.chat_bubble,
                label: formatCount(commentsCount),
                onTap: onCommentTap,
              ),
              // Repost Button
              GestureDetector(
                onTap: () {
                  _showRepostOptions(context, dbService, activePost);
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_2_circlepath,
                      color: dbService.isReposted(activePost.id)
                          ? Theme.of(context).primaryColor
                          : context.textPrimary.withValues(alpha: 0.75),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatCount(activePost.repostsCount),
                      style: TextStyle(
                        color: dbService.isReposted(activePost.id)
                            ? Theme.of(context).primaryColor
                            : context.textPrimary.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Save Button (Bookmark)
              GestureDetector(
                onTap: () {
                  final wasSaved = dbService.isSaved(activePost.id);
                  dbService.toggleSaveThread(activePost.id);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasSaved
                            ? "Removed from bookmarks"
                            : "Post saved to bookmarks",
                        style: GoogleFonts.inter(),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: wasSaved
                          ? Colors.grey[700]
                          : Theme.of(context).primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dbService.isSaved(activePost.id)
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color: dbService.isSaved(activePost.id)
                          ? Theme.of(context).primaryColor
                          : context.textPrimary.withValues(alpha: 0.75),
                      size: 18,
                    ),
                    if (activePost.savesCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatCount(activePost.savesCount),
                        style: TextStyle(
                          color: dbService.isSaved(activePost.id)
                              ? Theme.of(context).primaryColor
                              : context.textPrimary.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Share Button
              _buildActionButton(
                context: context,
                icon: CupertinoIcons.arrowshape_turn_up_right,
                label: formatCount(activePost.sharesCount),
                onTap: onShareTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: context.textPrimary.withValues(alpha: 0.75), size: 18),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRepostOptions(
      BuildContext context, DatabaseService dbService, ThreadPost post) {
    final targetPostId = post.isRepost && post.repostedPost != null
        ? post.repostedPost!.id
        : post.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(CupertinoIcons.arrow_2_circlepath,
                    color: context.textPrimary),
                title: Text('Repost',
                    style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary)),
                subtitle: Text('Instantly share this post to your feed',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  dbService.repostThread(targetPostId).then((success) {
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post status updated")),
                      );
                    }
                  });
                },
              ),
              Divider(height: 1, color: context.border),
              ListTile(
                leading: Icon(Icons.edit_note, color: context.textPrimary),
                title: Text('Quote Post',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary)),
                subtitle: Text('Share this post and add your own comment',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final targetPost =
                      post.isRepost && post.repostedPost != null
                          ? post.repostedPost!
                          : post;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: CreateThreadScreen(quotePost: targetPost),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }


}
