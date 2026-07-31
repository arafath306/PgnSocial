import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/general_settings_provider.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

import 'comment_attachment_picker_panel.dart';
import 'comment_item.dart';
import 'reply_input_composer.dart';
import 'content_report_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
part 'comments_sheet_extensions.dart';

class CommentsSheet extends StatefulWidget {
  final ThreadPost post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _sortedComments = [];
  bool _isLoading = false;
  String _sortBy = "Most relevant";
  
  Uint8List? _selectedImageBytes;
  String? _selectedGifUrl;
  int _pickerTabIndex = 0;
  bool _isUploading = false;
  bool _showEmojiPanel = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _replyToCommentId;
  String? _replyToUsername;

  String get _effectiveThreadId => widget.post.isRepost && widget.post.repostedPost != null
      ? widget.post.repostedPost!.id
      : widget.post.id;







  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final myProf = context.select((DatabaseService db) => db.myProfile);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85 - MediaQuery.of(context).viewInsets.bottom,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Comments",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.border),

            // Sort Filter Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    dropdownColor: context.cardBg,
                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: context.textPrimary),
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: ["Most relevant", "Newest", "Oldest"].map((val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          val,
                          style: GoogleFonts.inter(color: context.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _sortBy = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Comments List / Loading Indicator
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            "No comments found.",
                            style: GoogleFonts.inter(color: context.textMuted),
                          ),
                        )
                      : (() {
                          final settings = Provider.of<GeneralSettingsProvider>(context);
                          final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

                          int getPriority(Map<String, dynamic> c) {
                            if (!isPriorityEnabled) return 0;
                            // Wait, in comments_sheet, is 'profiles' available or is it mapped to 'author'?
                            // Let's check the code: final Profile author = comment['author'] as Profile;
                            final author = c['author'];
                            if (author == null) return 0;
                            if (author.badgeType == 'gold') return 3;
                            if (author.badgeType == 'gray') return 2;
                            if (author.isVerified == true) return 1;
                            return 0;
                          }

                          final sortedComments = List<Map<String, dynamic>>.from(_comments);
                          
                          sortedComments.sort((a, b) {
                            final pA = getPriority(a);
                            final pB = getPriority(b);
                            if (pA != pB) return pB.compareTo(pA);

                            if (_sortBy == "Newest") {
                              return (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? '');
                            } else if (_sortBy == "Oldest") {
                              return (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? '');
                            } else {
                              return (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0);
                            }
                          });
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedComments.length,
                            itemBuilder: (context, index) {
                              final comment = sortedComments[index];
                              final Profile author = comment['author'] as Profile;
                              final isPostAuthor = author.id == widget.post.userId;

                              return CommentItem(
                                comment: comment,
                                effectiveThreadId: _effectiveThreadId,
                                dbService: dbService,
                                post: widget.post,
                                isPostAuthor: isPostAuthor,
                                index: index,
                                isLast: index == sortedComments.length - 1,
                                onReloadComments: _loadComments,
                                onCommentDeleted: (deletedId) {
                                  setState(() {
                                    _comments.removeWhere((c) => c['id'] == deletedId);
                                    _sortComments();
                                  });
                                },
                                onCommentHidden: (hiddenId) {
                                  setState(() {
                                    _comments.removeWhere((c) => c['id'] == hiddenId);
                                    _sortComments();
                                  });
                                },
                              );
                            },
                          );
                      })(),
            ),

            // Sticky Bottom Input Composer
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(
                  top: BorderSide(color: context.border, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Replying to indicator
                  if (_replyToCommentId != null && _replyToUsername != null)
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
                              "Replying to @$_replyToUsername",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyToCommentId = null;
                                _replyToUsername = null;
                              });
                            },
                            child: Icon(Icons.close, size: 16, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),

                  // 2. Selected image preview
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

                  // Smooth Reusable Capsule Pill Box (X Style)
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
                    onSubmit: _submitComment,
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
            // Extra padding for safe area at bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Comment Quick Actions Bottom Sheet (Twitter/X Style) ──────────────────────
