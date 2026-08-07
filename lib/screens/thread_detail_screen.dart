import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/general_settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../widgets/comments_sheet.dart';
import '../utils/app_theme.dart';
import '../widgets/thread_detail/thread_detail_header.dart';
import '../widgets/thread_detail/thread_detail_body.dart';
import '../widgets/thread_detail/thread_detail_comments_list.dart';
import '../widgets/custom_thread_card.dart';
import 'package:flutter/services.dart';
import '../widgets/share_post_sheet.dart';
import '../widgets/comment_attachment_picker_panel.dart';
import '../widgets/reply_input_composer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/screenshot_protection_service.dart';

class ThreadDetailScreen extends StatefulWidget {
  final ThreadPost post;

  const ThreadDetailScreen({super.key, required this.post});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _scrolledHeader = false;
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
    _scrollController.addListener(_onScroll);
    if (widget.post.author.hasScreenshotProtection || widget.post.author.isPremium) {
      ScreenshotProtectionService.enableProtection();
    } else {
      ScreenshotProtectionService.disableProtection();
    }
    Future.microtask(() {
      if (!mounted) return;
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.incrementThreadViews(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    ScreenshotProtectionService.disableProtection();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    if (offset > 0 && !_scrolledHeader) {
      setState(() {
        _scrolledHeader = true;
      });
    } else if (offset <= 0 && _scrolledHeader) {
      setState(() {
        _scrolledHeader = false;
      });
    }
  }

  Future<void> _loadComments({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingComments = true;
      });
    }

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dbComments = await dbService.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          // Store ALL comments (top-level + replies). The UI at line ~641 filters topLevelComments,
          // then looks up replies from this same list — so we need the full set here.
          _comments = dbComments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() {
          _comments = [];
          _isLoadingComments = false;
        });
      }
    }
  }


  void _showPostQuickActions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    showThreadQuickActionsSheet(
      context: context,
      dbService: dbService,
      post: post,
      onDeletePost: () {
        if (context.mounted) {
          Navigator.pop(context); // Close detail screen on post deletion
        }
      },
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return isoString;
    }
  }

  void _postComment() async {
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
        widget.post.id,
        text,
        imageUrl: imageUrl,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedGifUrl = null;
          _showEmojiPanel = false;
        });
        _loadComments(silent: true);
      }
    } catch (e) {
      debugPrint("Post comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post comment: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
      debugPrint("Error picking comment image: $e");
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}m';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '$count';
  }







  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SharePostSheet(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final activePost = context.select<DatabaseService, ThreadPost>((db) => db.getLatestPost(widget.post));

    final settings = Provider.of<GeneralSettingsProvider>(context);
    final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

    int getPriority(Map<String, dynamic> c) {
      if (!isPriorityEnabled) return 0;
      final p = c['profiles'] as Map<String, dynamic>?;
      if (p == null) return 0;
      if (p['badge_type'] == 'gold') return 3;
      if (p['badge_type'] == 'gray') return 2;
      if (p['is_verified'] == true) return 1;
      return 0;
    }

    // Sort comments based on selected sort option
    final sortedComments = List<Map<String, dynamic>>.from(_comments);
    
    sortedComments.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      if (pA != pB) return pB.compareTo(pA); // higher priority first

      if (_sortBy == "Newest") {
        return (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? '');
      } else if (_sortBy == "Oldest") {
        return (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? '');
      } else {
        return (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0);
      }
    });

    // Separate top-level comments and nested replies
    final topLevelComments = sortedComments.where((c) => c['parent_id'] == null).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        leadingWidth: _scrolledHeader ? 0 : 56,
        leading: _scrolledHeader 
            ? const SizedBox.shrink()
            : IgnorePointer(
                ignoring: _scrolledHeader,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: context.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
        title: AnimatedOpacity(
          opacity: _scrolledHeader ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[800],
                backgroundImage: activePost.author.avatarUrl != null && activePost.author.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(activePost.author.avatarUrl!)
                    : null,
                child: activePost.author.avatarUrl == null || activePost.author.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activePost.author.fullName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    "${_formatCount(activePost.viewsCount)} views",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          AnimatedOpacity(
            opacity: _scrolledHeader ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_scrolledHeader,
              child: IconButton(
                icon: Icon(Icons.more_horiz, color: context.textPrimary),
                onPressed: () => _showPostQuickActions(context, dbService, activePost),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Details Header
                  ThreadDetailHeader(
                    activePost: activePost,
                    dbService: dbService,
                    onMoreTap: () => _showPostQuickActions(context, dbService, activePost),
                    formatTime: _formatTime,
                    formatCount: _formatCount,
                  ),

                  // Post content & Action buttons
                  ThreadDetailBody(
                    activePost: activePost,
                    dbService: dbService,
                    commentsCount: _comments.length,
                    onCommentTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => CommentsSheet(post: activePost),
                      ).then((_) => _loadComments(silent: true));
                    },
                    onShareTap: () => _sharePost(context),
                    formatCount: _formatCount,
                  ),

                  // Comments section
                  ThreadDetailCommentsList(
                    post: widget.post,
                    topLevelComments: topLevelComments,
                    isLoadingComments: _isLoadingComments,
                    sortBy: _sortBy,
                    onSortChanged: (val) {
                      setState(() {
                        _sortBy = val;
                      });
                    },
                    onReloadComments: () => _loadComments(silent: true),
                    onCommentDeleted: (cid) {
                      setState(() {
                        _comments.removeWhere((c) => c['id'] == cid);
                      });
                    },
                    onCommentHidden: (cid) {
                      setState(() {
                        _comments.removeWhere((c) => c['id'] == cid);
                      });
                    },
                    dbService: dbService,
                  ),
                ],
              ),
            ),
          ),
          // 1-to-1 X (Twitter) Borderless Capsule Pill Box
          Container(
            color: context.scaffoldBg,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Smooth Reusable Capsule Pill Box (X Style)
                  ReplyInputComposer(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    avatarUrl: dbService.myProfile?.avatarUrl,
                    hintText: "Post your reply",
                    onPickImage: _pickCommentImage,
                    onOpenGif: () {
                      _commentFocusNode.unfocus();
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
                      _commentFocusNode.unfocus();
                      setState(() {
                        if (_showEmojiPanel && _pickerTabIndex == 0) {
                          _showEmojiPanel = false;
                        } else {
                          _showEmojiPanel = true;
                          _pickerTabIndex = 0;
                        }
                      });
                    },
                    onSubmit: _postComment,
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
  );
  }

}
