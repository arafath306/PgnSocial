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
import '../thread_card_components/life_event_card.dart';

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
          if (activePost.content.isNotEmpty)
            Text(
              activePost.content,
              style: GoogleFonts.notoSansBengali(
                fontSize: 17.5,
                color: context.textPrimary,
                height: 1.45,
              ),
            ),
          if (activePost.lifeEvent != null) ...[
            const SizedBox(height: 12),
            LifeEventCard(
              lifeEvent: activePost.lifeEvent!,
              onCongratulate: () {
                HapticFeedback.lightImpact();
                if (!activePost.isLikedByMe) {
                  SoundService.playLike();
                }
                dbService.toggleLike(activePost.id, !activePost.isLikedByMe);
              },
            ),
          ],
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
          

          
          const SizedBox(height: 12),
          Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
          const SizedBox(height: 2),
          _buildMetadataRow(context),
          const SizedBox(height: 2),
          Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
          const SizedBox(height: 6),

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
                              size: 22,
                            )
                          : Icon(
                              CupertinoIcons.heart,
                              key: const ValueKey<int>(0),
                              color: context.textPrimary.withValues(alpha: 0.75),
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatCount(activePost.likesCount),
                      style: TextStyle(
                        color: activePost.isLikedByMe
                            ? Colors.red
                            : context.textPrimary.withValues(alpha: 0.75),
                        fontSize: 13.5,
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
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatCount(activePost.repostsCount),
                      style: TextStyle(
                        color: dbService.isReposted(activePost.id)
                            ? Theme.of(context).primaryColor
                            : context.textPrimary.withValues(alpha: 0.75),
                        fontSize: 13.5,
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
                      size: 22,
                    ),
                    if (activePost.savesCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatCount(activePost.savesCount),
                        style: TextStyle(
                          color: dbService.isSaved(activePost.id)
                              ? Theme.of(context).primaryColor
                              : context.textPrimary.withValues(alpha: 0.75),
                          fontSize: 13.5,
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
              color: context.textPrimary.withValues(alpha: 0.75), size: 22),
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
                    style: GoogleFonts.notoSansBengali(
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

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Widget _buildMetadataRow(BuildContext context) {
    final dt = activePost.createdDateTime;
    final viewsFormatted = formatCount(activePost.viewsCount);
    final primaryTextColor = context.textPrimary.withValues(alpha: 0.95);

    String? timeStr;
    String? dateStr;
    if (dt != null) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:$minute $period';

      final day = dt.day;
      final month = (dt.month >= 1 && dt.month <= 12) ? _monthNames[dt.month - 1] : '';
      final year = dt.year;
      dateStr = '$day $month $year';
    } else {
      final rawRel = activePost.createdAt.trim();
      final numMatch = RegExp(r'^(\d+)([dhm])$').firstMatch(rawRel);
      if (numMatch != null) {
        final val = int.tryParse(numMatch.group(1) ?? '') ?? 0;
        final unit = numMatch.group(2);
        DateTime approxDt = DateTime.now();
        if (unit == 'd') {
          approxDt = approxDt.subtract(Duration(days: val));
        } else if (unit == 'h') {
          approxDt = approxDt.subtract(Duration(hours: val));
        } else if (unit == 'm') {
          approxDt = approxDt.subtract(Duration(minutes: val));
        }
        final day = approxDt.day;
        final month = (approxDt.month >= 1 && approxDt.month <= 12) ? _monthNames[approxDt.month - 1] : '';
        final year = approxDt.year;
        dateStr = '$day $month $year';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (timeStr != null) ...[
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                  letterSpacing: -0.1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
            if (dateStr != null) ...[
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                  letterSpacing: -0.1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
            _buildSleekBarChartIcon(context, color: primaryTextColor),
            const SizedBox(width: 5),
            Text(
              '$viewsFormatted views',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekBarChartIcon(BuildContext context, {Color? color}) {
    final barColor = color ?? context.textPrimary.withValues(alpha: 0.95);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 2.4,
          height: 8.0,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.0),
          ),
        ),
        const SizedBox(width: 2.2),
        Container(
          width: 2.4,
          height: 15.0,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.0),
          ),
        ),
        const SizedBox(width: 2.2),
        Container(
          width: 2.4,
          height: 11.0,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.0),
          ),
        ),
      ],
    );
  }
}
