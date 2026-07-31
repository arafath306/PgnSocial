// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

part of 'comments_sheet.dart';

extension CommentsSheetExtensions on _CommentsSheetState {
  void _sortComments() {
    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
    final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

    int getPriority(Map<String, dynamic> c) {
      if (!isPriorityEnabled) return 0;
      final author = c['author'];
      if (author == null) return 0;
      if (author.badgeType == 'gold') return 3;
      if (author.badgeType == 'gray') return 2;
      if (author.isVerified == true) return 1;
      return 0;
    }

    _sortedComments = List<Map<String, dynamic>>.from(_comments);
    
    _sortedComments.sort((a, b) {
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
  }


  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      debugPrint("DEBUG: _effectiveThreadId is '$_effectiveThreadId', widget.post.id is '${widget.post.id}'");
      final comments = await dbService.fetchComments(_effectiveThreadId);
      if (mounted) {
        setState(() {
          // Filter: only display top-level comments (parent_id == null)
          _comments = comments.where((c) => c['parent_id'] == null).toList();
          _sortComments();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
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


  void _submitComment() async {
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
        _effectiveThreadId,
        text,
        parentId: _replyToCommentId,
        imageUrl: imageUrl,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedGifUrl = null;
          _replyToCommentId = null;
          _showEmojiPanel = false;
        });
        _loadComments();
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



}

class CommentQuickActionsSheet extends StatefulWidget {
  final Map<String, dynamic> comment;
  final DatabaseService dbService;
  final BuildContext parentContext;
  final Function(String) onCommentHidden;
  final Function(String)? onCommentDeleted;
  final Function(String, String)? onCommentEdited;

  const CommentQuickActionsSheet({
    super.key,
    required this.comment,
    required this.dbService,
    required this.parentContext,
    required this.onCommentHidden,
    this.onCommentDeleted,
    this.onCommentEdited,
  });

  @override
  State<CommentQuickActionsSheet> createState() => CommentQuickActionsSheetState();
}

class CommentQuickActionsSheetState extends State<CommentQuickActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  bool _isMuted = false;
  bool _isBlocked = false;
  bool _isFollowing = false;

  static const int _itemCount = 8;

  @override
  void initState() {
    super.initState();
    final author = widget.comment['author'] as Profile;
    _isFollowing = widget.dbService.isFollowingUser(author.id);
    _isMuted = widget.dbService.isMuted(author.id);
    _isBlocked = widget.dbService.isBlocked(author.id);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnims = List.generate(_itemCount, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 40.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _fadeAnims = List.generate(_itemCount, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(BuildContext ctx, String message,
      {String? undoLabel, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(ctx).primaryColor,
        duration: const Duration(seconds: 3),
        action: onUndo != null
            ? SnackBarAction(
                label: undoLabel ?? 'Undo',
                textColor: Colors.white,
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  void _showEditCommentDialog(BuildContext ctx, String commentId, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Comment", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.hindSiliguri(color: context.textPrimary),
          decoration: const InputDecoration(
            hintText: "Edit your comment...",
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(dialogCtx);
                if (widget.onCommentEdited != null) {
                  widget.onCommentEdited!(commentId, newContent);
                }
                final success = await widget.dbService.editComment(commentId, newContent);
                if (!ctx.mounted) return;
                if (success) {
                  _showSuccessSnackBar(ctx, "Comment updated successfully");
                }
              }
            },
            child: Text("Save", style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentConfirm(BuildContext ctx, String commentId) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Comment?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        content: Text(
          'Are you sure you want to permanently delete this comment?',
          style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (widget.onCommentDeleted != null) {
                widget.onCommentDeleted!(commentId);
              }
              final threadId = widget.comment['thread_id'] as String? ?? '';
              final parentId = widget.comment['parent_id'] as String?;
              final success = await widget.dbService.deleteComment(commentId, threadId, parentId: parentId);
              if (!ctx.mounted) return;
              if (success) {
                _showSuccessSnackBar(ctx, 'Comment deleted successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Profile author = widget.comment['author'] as Profile;
    final username = author.username;
    final commentId = widget.comment['id'] as String;
    final isMyComment = author.id == widget.dbService.currentUid;

    final List<_CommentQuickActionItem> actions;

    if (isMyComment) {
      actions = [
        _CommentQuickActionItem(
          icon: Icons.copy_rounded,
          label: 'Copy comment text',
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: widget.comment['content'] as String? ?? ''));
            _showSuccessSnackBar(widget.parentContext, 'Comment text copied');
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.edit_outlined,
          label: 'Edit comment',
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            _showEditCommentDialog(parentCtx, commentId, widget.comment['content'] as String? ?? '');
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.delete_outline,
          label: 'Delete comment',
          isDanger: true,
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            _showDeleteCommentConfirm(parentCtx, commentId);
          },
        ),
      ];
    } else {
      actions = [
        _CommentQuickActionItem(
          icon: Icons.sentiment_dissatisfied_outlined,
          label: 'Not interested in this comment',
          onTap: () {
            Navigator.pop(context);
            widget.onCommentHidden(commentId);
            _showSuccessSnackBar(context, 'Comment hidden from view',
                undoLabel: 'Undo', onUndo: () {});
          },
        ),
        _CommentQuickActionItem(
          icon: _isFollowing
              ? Icons.person_remove_outlined
              : Icons.person_add_alt_1_outlined,
          label: _isFollowing ? 'Unfollow @$username' : 'Follow @$username',
          onTap: () async {
            final wasFollowing = _isFollowing;
            setState(() {
              _isFollowing = !wasFollowing;
            });
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            await widget.dbService.toggleFollowUser(author.id);
            if (parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                wasFollowing
                    ? 'You unfollowed @$username'
                    : 'You are now following @$username',
              );
            }
          },
        ),

        _CommentQuickActionItem(
          icon: _isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          label: _isMuted ? 'Unmute @$username' : 'Mute @$username',
          onTap: () async {
            final wasMuted = _isMuted;
            setState(() {
              _isMuted = !wasMuted;
            });
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final settingsProvider = Provider.of<GeneralSettingsProvider>(parentCtx, listen: false);
            if (wasMuted) {
              await settingsProvider.unmuteAccount(author.id);
            } else {
              await settingsProvider.muteUserById(author.id);
            }
            await widget.dbService.fetchBlockedMutedLists();
            if (parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                wasMuted ? '@$username unmuted' : '@$username has been muted',
              );
            }
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.block_outlined,
          label: _isBlocked ? 'Unblock @$username' : 'Block @$username',
          isDanger: true,
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            if (_isBlocked) {
              _unblockUser(parentCtx, author.id, username);
            } else {
              _showBlockConfirm(parentCtx, username);
            }
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.flag_outlined,
          label: 'Report comment',
          isDanger: true,
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            ContentReportHelper.showReportSheet(
              context: parentCtx,
              targetId: commentId,
              targetAuthorUsername: author.username,
              targetAuthorUserId: author.id,
              contentType: 'comment',
            );
          },
        ),
      ];
    }

    return Container(
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
                color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            ...List.generate(actions.length, (i) {
              final action = actions[i];
              return AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnims[i].value),
                    child: Opacity(
                      opacity: _fadeAnims[i].value,
                      child: child,
                    ),
                  );
                },
                child: _buildActionTile(action),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(_CommentQuickActionItem item) {
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockConfirm(BuildContext ctx, String username) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block @$username?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When you block someone:',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.textPrimary)),
            const SizedBox(height: 8),
            _blockBullet(ctx, '• They cannot message or follow you'),
            _blockBullet(ctx, '• You will unfollow each other'),
            _blockBullet(ctx, '• They won\'t see your posts'),
            _blockBullet(ctx, '• You can unblock anytime from Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final author = widget.comment['author'] as Profile;
              final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
              await settingsProvider.blockUserById(author.id);
              await widget.dbService.fetchBlockedMutedLists();
              await widget.dbService.fetchFollowingList();
              if (ctx.mounted) {
                _showSuccessSnackBar(ctx, '@$username has been blocked');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Block',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _blockBullet(BuildContext ctx, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13, color: context.textSecondary, height: 1.4)),
    );
  }

  Future<void> _unblockUser(BuildContext ctx, String targetId, String username) async {
    final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
    await settingsProvider.unblockAccount(targetId);
    await widget.dbService.fetchBlockedMutedLists();
    await widget.dbService.fetchFollowingList();
    if (ctx.mounted) {
      _showSuccessSnackBar(ctx, '@$username has been unblocked');
    }
  }

}

class _CommentQuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  _CommentQuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}
