import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/comment_detail_screen.dart';
import '../utils/app_theme.dart';
import 'formatted_content_text.dart';
import 'share_comment_sheet.dart';
import 'comments_sheet.dart';
import 'verification_badge.dart';

class CommentItem extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String effectiveThreadId;
  final DatabaseService dbService;
  final ThreadPost post;
  final bool isPostAuthor;
  final int index;
  final bool isLast;
  final VoidCallback onReloadComments;
  final Function(String) onCommentDeleted;
  final Function(String) onCommentHidden;

  const CommentItem({
    super.key,
    required this.comment,
    required this.effectiveThreadId,
    required this.dbService,
    required this.post,
    required this.isPostAuthor,
    required this.index,
    required this.isLast,
    required this.onReloadComments,
    required this.onCommentDeleted,
    required this.onCommentHidden,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {

  void _showQuickActions(BuildContext context, Map<String, dynamic> comment, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => CommentQuickActionsSheet(
        comment: comment,
        dbService: dbService,
        parentContext: context,
        onCommentDeleted: widget.onCommentDeleted,
        onCommentHidden: widget.onCommentHidden,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Profile author = widget.comment['author'] as Profile;
    final bool isAnon = (widget.comment['is_anonymous'] as bool?) == true || author.id == 'anonymous' || author.username == 'anonymous' || author.username == 'pigeon_alias';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commenter Avatar
          Container(
            margin: const EdgeInsets.only(top: 1.5),
            child: GestureDetector(
              onTap: isAnon
                  ? null
                  : () {
                      final isOwn = author.id == (widget.dbService.myProfile?.id ?? widget.dbService.currentUid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                        ),
                      );
                    },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[900],
                backgroundImage: isAnon
                    ? const AssetImage('assets/anonymous_avatar.png') as ImageProvider
                    : ((author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(author.avatarUrl!)
                        : null),
                child: (!isAnon && (author.avatarUrl == null || author.avatarUrl!.isEmpty))
                    ? const Icon(Icons.person, size: 18, color: Colors.white54)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Comment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Header Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isAnon
                            ? null
                            : () {
                                final isOwn = author.id == (widget.dbService.myProfile?.id ?? widget.dbService.currentUid);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                                  ),
                                );
                              },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${author.fullName} ',
                                      style: GoogleFonts.hindSiliguri(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    if (!isAnon && author.isVerified)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 4, bottom: 2),
                                          child: VerificationBadge(
                                            isVerified: true,
                                            badgeType: author.badgeType,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    TextSpan(
                                      text: isAnon ? '@pigeon_alias' : '@${author.username}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.comment['created_at'] != null && widget.comment['created_at'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '· ${widget.comment['created_at']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.isPostAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Author",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.more_horiz, size: 18, color: context.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showQuickActions(context, widget.comment, widget.dbService),
                    ),
                  ],
                ),
                const SizedBox(height: 1.5),

                // Content Text
                FormattedContentText(
                  text: widget.comment['content'] as String,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15.5,
                    color: context.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (widget.comment['image_url'] != null && (widget.comment['image_url'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.comment['image_url'] as String,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Action Row
                Row(
                  children: [
                    // Likes metric
                    GestureDetector(
                      onTap: () {
                        final bool currentVal = widget.comment['is_liked_by_me'] as bool? ?? false;
                        final bool newVal = !currentVal;
                        final int currentLikes = widget.comment['likes_count'] as int? ?? 0;
                        
                        setState(() {
                          widget.comment['is_liked_by_me'] = newVal;
                          widget.comment['likes_count'] = newVal 
                              ? currentLikes + 1 
                              : (currentLikes > 0 ? currentLikes - 1 : 0);
                        });
                        widget.dbService.toggleCommentLike(widget.comment['id'] as String, newVal);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              (widget.comment['is_liked_by_me'] as bool? ?? false)
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              size: 17,
                              color: (widget.comment['is_liked_by_me'] as bool? ?? false)
                                  ? Colors.red
                                  : context.textPrimary.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.comment['likes_count'] ?? 0}",
                              style: GoogleFonts.inter(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Comments/Replies metric (opens CommentDetailScreen)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentDetailScreen(
                              comment: widget.comment,
                              threadId: widget.effectiveThreadId,
                            ),
                          ),
                        ).then((_) => widget.onReloadComments());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.chat_bubble, size: 17, color: context.textPrimary.withValues(alpha: 0.75)),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.comment['replies_count'] ?? 0}",
                              style: GoogleFonts.inter(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Save/Bookmark comment
                    GestureDetector(
                      onTap: () {
                        final bool currentSaved = widget.comment['is_saved_by_me'] as bool? ?? false;
                        final bool newSaved = !currentSaved;
                        final int currentSaves = widget.comment['saves_count'] as int? ?? 0;

                        setState(() {
                          widget.comment['is_saved_by_me'] = newSaved;
                          widget.comment['saves_count'] = newSaved 
                              ? currentSaves + 1 
                              : (currentSaves > 0 ? currentSaves - 1 : 0);
                        });
                        widget.dbService.toggleSaveComment(widget.comment['id'] as String);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              (widget.comment['is_saved_by_me'] as bool? ?? false)
                                  ? CupertinoIcons.bookmark_fill
                                  : CupertinoIcons.bookmark,
                              size: 17,
                              color: (widget.comment['is_saved_by_me'] as bool? ?? false)
                                  ? Theme.of(context).primaryColor
                                  : context.textPrimary.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.comment['saves_count'] ?? 0}",
                              style: GoogleFonts.inter(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Share Comment
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetCtx) => ShareCommentSheet(comment: widget.comment),
                        ).then((_) {
                          widget.onReloadComments();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.arrowshape_turn_up_right, size: 17, color: context.textPrimary.withValues(alpha: 0.75)),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.comment['shares_count'] ?? 0}",
                              style: GoogleFonts.inter(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (!widget.isLast) ...[
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
