import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/share_comment_sheet.dart';
import '../widgets/comments_sheet.dart';

import '../widgets/comment_attachment_picker_panel.dart';
import '../widgets/reply_input_composer.dart';
import '../widgets/verification_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String threadId;

  const CommentDetailScreen({
    super.key,
    required this.comment,
    required this.threadId,
  });

  @override
  State<CommentDetailScreen> createState() => _CommentDetailScreenState();
}

class _CommentDetailScreenState extends State<CommentDetailScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late Map<String, dynamic> _fatherComment;
  List<Map<String, dynamic>> _replies = [];
  bool _isLoadingReplies = false;
  bool _isUploading = false;
  bool _showEmojiPanel = false;
  Uint8List? _selectedImageBytes;
  String? _selectedGifUrl;
  int _pickerTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fatherComment = Map<String, dynamic>.from(widget.comment);
    _loadReplies();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _isLoadingReplies = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final replies = await dbService.fetchCommentReplies(_fatherComment['id'] as String);
      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoadingReplies = false;
        });
      }
    } catch (e) {
      debugPrint("Load replies error: $e");
      if (mounted) {
        setState(() => _isLoadingReplies = false);
      }
    }
  }

  Future<void> _refreshFatherComment() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final updated = await dbService.fetchSingleComment(_fatherComment['id'] as String);
      if (updated != null && mounted) {
        setState(() {
          _fatherComment = updated;
        });
      }
    } catch (e) {
      debugPrint("Refresh father comment error: $e");
    }
  }

  Future<void> _pickCommentImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedGifUrl = null;
      });
    } catch (e) {
      debugPrint("Error picking reply image: $e");
    }
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    
    if (!selection.isValid) {
      _commentController.text = text + emoji;
      return;
    }
    
    final start = selection.start;
    final end = selection.end;
    
    final newText = text.replaceRange(start, end, emoji);
    _commentController.text = newText;
    
    _commentController.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
  }

  void _submitReply() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null && _selectedGifUrl == null) return;

    setState(() => _isUploading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    String? imageUrl;
    try {
      if (_selectedGifUrl != null) {
        imageUrl = _selectedGifUrl;
      } else if (_selectedImageBytes != null) {
        imageUrl = await dbService.uploadPostImage(_selectedImageBytes!);
      }

      final success = await dbService.addComment(
        widget.threadId,
        text,
        parentId: _fatherComment['id'] as String?,
        imageUrl: imageUrl,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedGifUrl = null;
          _showEmojiPanel = false;
          // Optimistically increment replies_count on the father comment
          final currentReplies = _fatherComment['replies_count'] as int? ?? 0;
          _fatherComment['replies_count'] = currentReplies + 1;
        });
        _loadReplies();
      }
    } catch (e) {
      debugPrint("Post reply error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post reply: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showQuickActions(BuildContext context, Map<String, dynamic> comment, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (sheetContext) => CommentQuickActionsSheet(
        comment: comment,
        dbService: dbService,
        parentContext: context,
        onCommentHidden: (id) {
          if (id == _fatherComment['id']) {
            Navigator.pop(context);
          } else {
            setState(() {
              _replies.removeWhere((c) => c['id'] == id || c['parent_id'] == id);
            });
          }
        },
        onCommentDeleted: (id) {
          if (id == _fatherComment['id']) {
            Navigator.pop(context);
          } else {
            setState(() {
              _replies.removeWhere((c) => c['id'] == id || c['parent_id'] == id);
            });
          }
        },
        onCommentEdited: (id, newContent) {
          setState(() {
            if (id == _fatherComment['id']) {
              _fatherComment['content'] = newContent;
            } else {
              final idx = _replies.indexWhere((c) => c['id'] == id);
              if (idx != -1) {
                _replies[idx]['content'] = newContent;
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final myProf = context.select<DatabaseService, Profile?>((db) => db.myProfile);
    final Profile author = _fatherComment['author'] as Profile;

    return Scaffold(
      backgroundColor: context.cardBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.cardBg,
        centerTitle: false,
        title: Text(
          "Thread Reply",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: Theme.of(context).primaryColor,
                onRefresh: () async {
                  await _refreshFatherComment();
                  await _loadReplies();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FATHER COMMENT CARD (Flat, matching CommentsSheet list items)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final isOwn = author.id == (dbService.myProfile?.id ?? dbService.currentUid);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(author.avatarUrl!)
                                  : null,
                              child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 20, color: Colors.white54)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Row(
                                   children: [
                                     Expanded(
                                       child: GestureDetector(
                                         onTap: () {
                                           final isOwn = author.id == (dbService.myProfile?.id ?? dbService.currentUid);
                                           Navigator.push(
                                             context,
                                             MaterialPageRoute(
                                               builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                                             ),
                                           );
                                         },
                                         child: Text.rich(
                                           TextSpan(
                                             children: [
                                               TextSpan(
                                                 text: author.fullName,
                                                 style: GoogleFonts.hindSiliguri(
                                                   fontWeight: FontWeight.w700,
                                                   fontSize: 15.5,
                                                   color: context.textPrimary,
                                                 ),
                                               ),
                                                if (author.isVerified)
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.middle,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left: 4),
                                                      child: VerificationBadge(
                                                        isVerified: true,
                                                        badgeType: author.badgeType,
                                                        size: 15,
                                                      ),
                                                    ),
                                                  ),
                                               TextSpan(
                                                 text: ' @${author.username}',
                                                 style: GoogleFonts.inter(
                                                   fontSize: 13.5,
                                                   color: context.textSecondary,
                                                 ),
                                               ),
                                               TextSpan(
                                                 text: ' · ${_fatherComment['created_at']}',
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
                                     ),
                                     const SizedBox(width: 8),
                                     IconButton(
                                       icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       onPressed: () => _showQuickActions(context, _fatherComment, dbService),
                                     ),
                                   ],
                                 ),
                                const SizedBox(height: 4),
                                Text(
                                  _fatherComment['content'] as String,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 16.0,
                                    color: context.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                                if (_fatherComment['image_url'] != null && (_fatherComment['image_url'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _fatherComment['image_url'] as String,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                // Actions Row
                                Row(
                                  children: [
                                    // Like
                                    GestureDetector(
                                      onTap: () {
                                        final bool currentVal = _fatherComment['is_liked_by_me'] as bool? ?? false;
                                        final bool newVal = !currentVal;
                                        final int currentLikes = _fatherComment['likes_count'] as int? ?? 0;
                                        
                                        setState(() {
                                          _fatherComment['is_liked_by_me'] = newVal;
                                          _fatherComment['likes_count'] = newVal 
                                              ? currentLikes + 1 
                                              : (currentLikes > 0 ? currentLikes - 1 : 0);
                                        });
                                        dbService.toggleCommentLike(_fatherComment['id'] as String, newVal);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            (_fatherComment['is_liked_by_me'] as bool? ?? false)
                                                ? CupertinoIcons.heart_fill
                                                : CupertinoIcons.heart,
                                            size: 15,
                                            color: (_fatherComment['is_liked_by_me'] as bool? ?? false)
                                                ? Colors.red
                                                : context.textPrimary.withValues(alpha: 0.75),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${_fatherComment['likes_count'] ?? 0}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimary.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Reply count (opens keyboard)
                                    GestureDetector(
                                      onTap: () => _focusNode.requestFocus(),
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.chat_bubble, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${_fatherComment['replies_count'] ?? 0}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimary.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Save
                                    GestureDetector(
                                      onTap: () {
                                        final bool currentSaved = _fatherComment['is_saved_by_me'] as bool? ?? false;
                                        final bool newSaved = !currentSaved;
                                        final int currentSaves = _fatherComment['saves_count'] as int? ?? 0;

                                        setState(() {
                                          _fatherComment['is_saved_by_me'] = newSaved;
                                          _fatherComment['saves_count'] = newSaved 
                                              ? currentSaves + 1 
                                              : (currentSaves > 0 ? currentSaves - 1 : 0);
                                        });
                                        dbService.toggleSaveComment(_fatherComment['id'] as String);
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            (_fatherComment['is_saved_by_me'] as bool? ?? false)
                                                ? CupertinoIcons.bookmark_fill
                                                : CupertinoIcons.bookmark,
                                            size: 15,
                                            color: (_fatherComment['is_saved_by_me'] as bool? ?? false)
                                                ? Theme.of(context).primaryColor
                                                : context.textPrimary.withValues(alpha: 0.75),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${_fatherComment['saves_count'] ?? 0}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimary.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Share
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (sheetCtx) => ShareCommentSheet(comment: _fatherComment),
                                        ).then((_) {
                                          _refreshFatherComment();
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.arrowshape_turn_up_right, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${_fatherComment['shares_count'] ?? 0}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimary.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: context.border, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        "Replies",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // REPLIES LIST
                      if (_isLoadingReplies)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                          ),
                        )
                      else if (_replies.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(CupertinoIcons.chat_bubble, size: 48, color: context.textMuted.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  "No replies yet. Be the first to reply!",
                                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _replies.length,
                          separatorBuilder: (context, index) => Divider(height: 24, color: context.border),
                          itemBuilder: (context, index) {
                            final reply = _replies[index];
                            final Profile rAuthor = reply['author'] as Profile;
                            return RepaintBoundary(
                              child: Container(
                                margin: EdgeInsets.zero,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final isOwn = rAuthor.id == (dbService.myProfile?.id ?? dbService.currentUid);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProfileScreen(userId: isOwn ? null : rAuthor.id),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: (rAuthor.avatarUrl != null && rAuthor.avatarUrl!.isNotEmpty)
                                          ? CachedNetworkImageProvider(rAuthor.avatarUrl!)
                                          : null,
                                      child: (rAuthor.avatarUrl == null || rAuthor.avatarUrl!.isEmpty)
                                          ? const Icon(Icons.person, size: 18, color: Colors.white54)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  final isOwn = rAuthor.id == (dbService.myProfile?.id ?? dbService.currentUid);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ProfileScreen(userId: isOwn ? null : rAuthor.id),
                                                    ),
                                                  );
                                                },
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: rAuthor.fullName,
                                                        style: GoogleFonts.hindSiliguri(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15.5,
                                                          color: context.textPrimary,
                                                        ),
                                                      ),
                                                      if (rAuthor.isVerified)
                                                        WidgetSpan(
                                                          alignment: PlaceholderAlignment.middle,
                                                          child: Padding(
                                                            padding: const EdgeInsets.only(left: 4),
                                                            child: VerificationBadge(
                                                              isVerified: true,
                                                              badgeType: rAuthor.badgeType,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      TextSpan(
                                                        text: ' @${rAuthor.username}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13.5,
                                                          color: context.textSecondary,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: ' · ${reply['created_at']}',
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
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(CupertinoIcons.ellipsis, size: 18, color: Colors.grey),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _showQuickActions(context, reply, dbService),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          reply['content'] as String,
                                          style: GoogleFonts.hindSiliguri(
                                            fontSize: 15.0,
                                            color: context.textPrimary,
                                            height: 1.45,
                                          ),
                                        ),
                                        if (reply['image_url'] != null && (reply['image_url'] as String).isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: reply['image_url'] as String,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => const SizedBox.shrink(),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // Like
                                            GestureDetector(
                                              onTap: () {
                                                final bool currentVal = reply['is_liked_by_me'] as bool? ?? false;
                                                final bool newVal = !currentVal;
                                                final int currentLikes = reply['likes_count'] as int? ?? 0;
                                                
                                                setState(() {
                                                  reply['is_liked_by_me'] = newVal;
                                                  reply['likes_count'] = newVal 
                                                      ? currentLikes + 1 
                                                      : (currentLikes > 0 ? currentLikes - 1 : 0);
                                                });
                                                dbService.toggleCommentLike(reply['id'] as String, newVal);
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    (reply['is_liked_by_me'] as bool? ?? false)
                                                        ? CupertinoIcons.heart_fill
                                                        : CupertinoIcons.heart,
                                                    size: 15,
                                                    color: (reply['is_liked_by_me'] as bool? ?? false)
                                                        ? Colors.red
                                                        : context.textPrimary.withValues(alpha: 0.75),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${reply['likes_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            // Reply
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => CommentDetailScreen(
                                                      comment: reply,
                                                      threadId: widget.threadId,
                                                    ),
                                                  ),
                                                ).then((_) => _loadReplies());
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(CupertinoIcons.chat_bubble, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${reply['replies_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            // Save
                                            GestureDetector(
                                              onTap: () {
                                                final bool currentSaved = reply['is_saved_by_me'] as bool? ?? false;
                                                final bool newSaved = !currentSaved;
                                                final int currentSaves = reply['saves_count'] as int? ?? 0;

                                                setState(() {
                                                  reply['is_saved_by_me'] = newSaved;
                                                  reply['saves_count'] = newSaved 
                                                      ? currentSaves + 1 
                                                      : (currentSaves > 0 ? currentSaves - 1 : 0);
                                                });
                                                dbService.toggleSaveComment(reply['id'] as String);
                                                ScaffoldMessenger.of(context).clearSnackBars();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    (reply['is_saved_by_me'] as bool? ?? false)
                                                        ? CupertinoIcons.bookmark_fill
                                                        : CupertinoIcons.bookmark,
                                                    size: 15,
                                                    color: (reply['is_saved_by_me'] as bool? ?? false)
                                                        ? Theme.of(context).primaryColor
                                                        : context.textPrimary.withValues(alpha: 0.75),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${reply['saves_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            // Share
                                            GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (sheetCtx) => ShareCommentSheet(comment: reply),
                                                ).then((_) {
                                                  _loadReplies();
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(CupertinoIcons.arrowshape_turn_up_right, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${reply['shares_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ));
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // STICKY BOTTOM INPUT COMPOSER (Unified with ReplyInputComposer)
            Container(
              color: context.scaffoldBg,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Replying to indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: context.isDarkMode ? Colors.black26 : Colors.grey[100],
                      width: double.infinity,
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 14, color: context.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Replying to @${author.username}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selected image preview
                    if (_selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60, top: 12, bottom: 4),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.border, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Selected GIF preview
                    if (_selectedGifUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60, top: 12, bottom: 4),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.border, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: _selectedGifUrl!,
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGifUrl = null;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Unified X Style Capsule Pill Box
                    ReplyInputComposer(
                      controller: _commentController,
                      focusNode: _focusNode,
                      avatarUrl: myProf?.avatarUrl,
                      hintText: "Post your reply",
                      onPickImage: _pickCommentImage,
                      onOpenGif: () {
                        _focusNode.unfocus();
                        setState(() {
                          if (_showEmojiPanel && _pickerTabIndex == 1) {
                            _showEmojiPanel = false;
                          } else {
                            _showEmojiPanel = true;
                            _pickerTabIndex = 1;
                          }
                        });
                      },
                      onOpenEmoji: () {
                        _focusNode.unfocus();
                        setState(() {
                          if (_showEmojiPanel && _pickerTabIndex == 0) {
                            _showEmojiPanel = false;
                          } else {
                            _showEmojiPanel = true;
                            _pickerTabIndex = 0;
                          }
                        });
                      },
                      onSubmit: _submitReply,
                      isUploading: _isUploading,
                      hasSelectedMedia: _selectedImageBytes != null || _selectedGifUrl != null,
                      showEmojiPanel: _showEmojiPanel,
                      pickerTabIndex: _pickerTabIndex,
                    ),
                  // Premium Emoji / GIF Picker Panel
                  if (_showEmojiPanel)
                    CommentAttachmentPickerPanel(
                      initialTabIndex: _pickerTabIndex,
                      onEmojiSelected: (emoji) {
                        _insertEmoji(emoji);
                      },
                      onGifSelected: (gifUrl) {
                        setState(() {
                          _selectedGifUrl = gifUrl;
                          _selectedImageBytes = null; // Clear image when GIF is selected
                          _showEmojiPanel = false; // Close panel on selection
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
