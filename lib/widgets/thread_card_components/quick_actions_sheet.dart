part of '../custom_thread_card.dart';

class _QuickActionsSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;
  final BuildContext parentContext;
  final bool isCommunityModerator;
  final VoidCallback? onDeletePost;

  const _QuickActionsSheet({
    required this.post,
    required this.dbService,
    required this.parentContext,
    this.isCommunityModerator = false,
    this.onDeletePost,
  });

  @override
  State<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<_QuickActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  bool _isMuted = false;
  bool _isBlocked = false;
  bool _isFollowing = false;

  static const int _itemCount = 6;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.dbService.isFollowingUser(widget.post.userId);
    _isMuted = widget.dbService.isMuted(widget.post.userId);
    _isBlocked = widget.dbService.isBlocked(widget.post.userId);

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
        backgroundColor: const Color(0xFF1E824C),
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

  @override
  Widget build(BuildContext context) {
    final username = widget.post.author.username;

    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sentiment_dissatisfied_outlined,
        label: 'Not interested in this post',
        onTap: () async {
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          final success = await widget.dbService.hideThreadForCurrentUser(widget.post.id);
          if (success && parentCtx.mounted) {
            _showSuccessSnackBar(parentCtx, 'Post hidden from your feed',
                undoLabel: 'Undo', onUndo: () async {
                  await widget.dbService.unhideThreadForCurrentUser(widget.post.id);
                });
          }
        },
      ),
      _QuickActionItem(
        icon: _isFollowing
            ? Icons.person_remove_outlined
            : Icons.person_add_alt_1_outlined,
        label: _isFollowing ? 'Unfollow @$username' : 'Follow @$username',
        onTap: () async {
          final parentCtx = widget.parentContext;
          final wasFollowing = _isFollowing;
          Navigator.pop(context);
          await widget.dbService.toggleFollowUser(widget.post.userId);
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

      _QuickActionItem(
        icon: _isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
        label: _isMuted ? 'Unmute @$username' : 'Mute @$username',
        onTap: () async {
          final parentCtx = widget.parentContext;
          final wasMuted = _isMuted;
          final settingsProvider = Provider.of<GeneralSettingsProvider>(parentCtx, listen: false);
          Navigator.pop(context);
          if (wasMuted) {
            await settingsProvider.unmuteAccount(widget.post.userId);
          } else {
            await settingsProvider.muteUserById(widget.post.userId);
          }
          await widget.dbService.fetchBlockedMutedLists();
          await widget.dbService.fetchFeed();
          if (parentCtx.mounted) {
            _showSuccessSnackBar(
              parentCtx,
              wasMuted ? '@$username unmuted' : '@$username has been muted',
              undoLabel: 'Undo',
              onUndo: () async {
                if (wasMuted) {
                  await settingsProvider.muteUserById(widget.post.userId);
                } else {
                  await settingsProvider.unmuteAccount(widget.post.userId);
                }
                await widget.dbService.fetchBlockedMutedLists();
                await widget.dbService.fetchFeed();
              },
            );
          }
        },
      ),
      _QuickActionItem(
        icon: Icons.block_outlined,
        label: _isBlocked ? 'Unblock @$username' : 'Block @$username',
        isDanger: true,
        onTap: () {
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          _showBlockConfirm(parentCtx, username);
        },
      ),
      _QuickActionItem(
        icon: Icons.flag_outlined,
        label: 'Report post',
        isDanger: true,
        onTap: () {
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          ContentReportHelper.showReportSheet(
            context: parentCtx,
            targetId: widget.post.id,
            targetAuthorUsername: widget.post.author.username,
            targetAuthorUserId: widget.post.userId,
            contentType: 'post',
          );
        },
      ),
      if (widget.isCommunityModerator)
        _QuickActionItem(
          icon: Icons.delete_outline,
          label: 'Delete post as Moderator',
          isDanger: true,
          onTap: () {
            Navigator.pop(context);
            // Re-use _showDeleteConfirm but from _QuickActionsSheet
            _showDeleteConfirm(widget.parentContext);
          },
        ),
    ];

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
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
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

  Widget _buildActionTile(_QuickActionItem item) {
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: const Color(0xFF1E824C).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1E824C).withValues(alpha: 0.04),
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
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18,
              color: context.textPrimary),
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
            _bullet(ctx, '• They cannot message or follow you'),
            _bullet(ctx, '• You will unfollow each other'),
            _bullet(ctx, '• They won\'t see your posts'),
            _bullet(ctx, '• You can unblock anytime from Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final settingsProvider =
                  Provider.of<GeneralSettingsProvider>(ctx, listen: false);
              await settingsProvider.blockUserById(widget.post.userId);
              await widget.dbService.fetchBlockedMutedLists();
              await widget.dbService.fetchFollowingList();
              await widget.dbService.fetchFeed();
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

  Widget _bullet(BuildContext ctx, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13, color: context.textSecondary, height: 1.4)),
    );
  }

  void _showCustomReasonDialog(BuildContext parentCtx, String title, Function(String) onSubmit) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: parentCtx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: parentCtx.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: parentCtx.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_rounded, color: Color(0xFF1E824C), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: parentCtx.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please describe the issue in detail',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: parentCtx.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: parentCtx.textPrimary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Provide details about why you are reporting this...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: parentCtx.textMuted,
                      ),
                      filled: true,
                      fillColor: parentCtx.isDarkMode ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: parentCtx.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: parentCtx.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: parentCtx.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final customReason = controller.text.trim();
                            if (customReason.isNotEmpty) {
                              Navigator.pop(sheetCtx);
                              onSubmit('Other: $customReason');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Submit Report',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportSuccessActionsSheet(BuildContext ctx, String username) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E824C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thanks for letting us know',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: ctx.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'We use these reports to keep Pigeon safe for everyone.',
                            style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: ctx.border),
                const SizedBox(height: 16),
                Text(
                  'What else you can do:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ctx.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block_outlined, color: Colors.redAccent),
                  title: Text('Block @$username', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  subtitle: Text('They won\'t be able to see your posts or contact you.', style: GoogleFonts.inter(fontSize: 12, color: ctx.textSecondary)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showBlockConfirm(ctx, username);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.volume_off_outlined, color: Colors.orangeAccent),
                  title: Text('Mute @$username', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: ctx.textPrimary)),
                  subtitle: Text('Stop seeing posts from @$username in your feed.', style: GoogleFonts.inter(fontSize: 12, color: ctx.textSecondary)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
                    await settingsProvider.muteUserById(widget.post.userId);
                    await widget.dbService.fetchBlockedMutedLists();
                    await widget.dbService.fetchFeed();
                    if (ctx.mounted) {
                      _showSuccessSnackBar(ctx, '@$username has been muted');
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubCategoryReportSheet(BuildContext ctx, String mainCategory, List<String> subCategories) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (subCtx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  mainCategory,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ctx.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select a specific reason to help us understand:',
                  style: GoogleFonts.inter(fontSize: 13, color: ctx.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: ctx.border),
              ...subCategories.map((subCat) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(subCtx);
                        final fullReason = '$mainCategory - $subCat';
                        final success = await widget.dbService.reportPost(widget.post.id, fullReason);
                        if (!ctx.mounted) return;
                        if (success) {
                          _showReportSuccessActionsSheet(ctx, widget.post.author.username);
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subCat,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: ctx.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: ctx.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext ctx) {
    final categoryMap = <String, List<String>>{
      'Harassment or Bullying': [
        'It\'s harassing me directly',
        'It\'s harassing a friend or family member',
        'It\'s harassing someone else / public figure',
      ],
      'Hate Speech or Discrimination': [
        'Race, ethnicity or national origin',
        'Religious beliefs or practices',
        'Gender identity or sexual orientation',
        'Disability or medical condition',
      ],
      'Nudity or Sexual Content': [
        'Nudity or explicit exposure',
        'Explicit sexual acts or pornography',
        'Non-consensual sexual content / abuse',
      ],
      'Violence, Threat or Danger': [
        'Direct threat of physical violence',
        'Self-harm or suicide encouragement',
        'Dangerous or violent organization',
      ],
      'Scam, Fraud or Impersonation': [
        'Pretending to be me or someone I know',
        'Phishing, financial or crypto scam',
        'Spam or fake automated account',
      ],
      'False Information / Misinformation': [
        'Medical or health misinformation',
        'Political or election misinformation',
        'Fraudulent news / Dangerous hoax',
      ],
      'Intellectual Property Violation': [
        'Copyright infringement',
        'Trademark or brand violation',
      ],
      'Other Issue (specify details)': [],
    };

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (reportCtx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Report post',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ctx.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select a category that best describes this issue:',
                    style: GoogleFonts.inter(fontSize: 13, color: ctx.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: ctx.border),
                ...categoryMap.entries.map((entry) {
                  final catTitle = entry.key;
                  final subCats = entry.value;
                  final isOther = subCats.isEmpty;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(reportCtx);
                        if (isOther) {
                          _showCustomReasonDialog(ctx, 'Report Post', (finalReason) async {
                            final success = await widget.dbService.reportPost(widget.post.id, finalReason);
                            if (!ctx.mounted) return;
                            if (success) {
                              _showReportSuccessActionsSheet(ctx, widget.post.author.username);
                            }
                          });
                        } else {
                          _showSubCategoryReportSheet(ctx, catTitle, subCats);
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                catTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: isOther ? FontWeight.w600 : FontWeight.w500,
                                  color: isOther ? Colors.redAccent : ctx.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: ctx.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Post?',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          'As a moderator, you can delete this post. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await widget.dbService.deletePost(widget.post.id);
              if (success && ctx.mounted) {
                _showSuccessSnackBar(ctx, 'Post deleted successfully');
                widget.onDeletePost?.call();
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
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}

class _AuthorActionsSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;
  final BuildContext parentContext;
  final VoidCallback? onDeletePost;

  const _AuthorActionsSheet({
    required this.post,
    required this.dbService,
    required this.parentContext,
    this.onDeletePost,
  });

  @override
  State<_AuthorActionsSheet> createState() => _AuthorActionsSheetState();
}

class _AuthorActionsSheetState extends State<_AuthorActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  
  static const int _itemCount = 6;

  @override
  void initState() {
    super.initState();
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

  void _showSuccessSnackBar(BuildContext ctx, String message) {
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
        backgroundColor: const Color(0xFF1E824C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEditRepostDialog(BuildContext ctx, ThreadPost post) {
    final controller = TextEditingController(text: post.quoteText);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Quote", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: ctx.textPrimary)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.hindSiliguri(color: ctx.textPrimary),
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
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await widget.dbService.editRepost(post.id, newText);
                if (success && ctx.mounted) {
                  _showSuccessSnackBar(ctx, "Quote updated successfully");
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFF1E824C))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Post?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'This action is permanent and cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await widget.dbService.deletePost(widget.post.id);
              if (success && ctx.mounted) {
                _showSuccessSnackBar(ctx, 'Post deleted successfully');
                widget.onDeletePost?.call();
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

  void _showEditPostSheet(BuildContext ctx) {
    // Navigate to the full composer screen in edit mode.
    // This avoids the "unmounted widget" error that the bottom-sheet approach had.
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => CreateThreadScreen(editPost: widget.post),
      ),
    );
  }


  void _showHideSpecificUsersSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _HidePostForUsersSheet(
        post: widget.post,
        dbService: widget.dbService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPinned = widget.post.isPinned;
    final isMuted = widget.post.muteNotifications;
    final isHiddenFromProfile = widget.post.hideFromProfile;

    final actions = <_QuickActionItem>[];
    if (widget.post.isRepost) {
      actions.addAll([
        _QuickActionItem(
          icon: Icons.delete_outline,
          label: 'Remove repost',
          isDanger: true,
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.deleteRepost(widget.post.id, widget.post.repostedPost?.id ?? '');
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(parentCtx, 'Repost removed');
              widget.onDeletePost?.call();
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                isMuted ? 'Notifications unmuted' : 'Notifications muted for this post',
              );
            }
          },
        ),
        if (widget.post.quoteText != null && widget.post.quoteText!.isNotEmpty)
          _QuickActionItem(
            icon: Icons.edit_outlined,
            label: 'Edit post',
            onTap: () {
              Navigator.pop(context);
              _showEditRepostDialog(widget.parentContext, widget.post);
            },
          ),
      ]);
    } else {
      actions.addAll([
        _QuickActionItem(
          icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: isPinned ? 'Unpin from profile' : 'Pin to profile',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.togglePinPost(widget.post.id, !isPinned);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                isPinned ? 'Post unpinned from profile' : 'Post pinned to profile',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                isMuted ? 'Notifications unmuted' : 'Notifications muted for this post',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: Icons.edit_outlined,
          label: 'Edit post',
          onTap: () {
            Navigator.pop(context);
            _showEditPostSheet(widget.parentContext);
          },
        ),
        _QuickActionItem(
          icon: isHiddenFromProfile ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          label: isHiddenFromProfile ? 'Show on profile' : 'Hide from my profile',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleHidePostFromProfile(widget.post.id, !isHiddenFromProfile);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                isHiddenFromProfile ? 'Post is now visible on your profile' : 'Post hidden from your profile feed',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: Icons.person_off_outlined,
          label: 'Hide for specific users',
          onTap: () {
            Navigator.pop(context);
            _showHideSpecificUsersSheet(widget.parentContext);
          },
        ),
        _QuickActionItem(
          icon: Icons.delete_outline,
          label: 'Delete post',
          isDanger: true,
          onTap: () {
            Navigator.pop(context);
            _showDeleteConfirm(widget.parentContext);
          },
        ),
      ]);
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
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
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

  Widget _buildActionTile(_QuickActionItem item) {
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: const Color(0xFF1E824C).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1E824C).withValues(alpha: 0.04),
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
}

class _HidePostForUsersSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;

  const _HidePostForUsersSheet({required this.post, required this.dbService});

  @override
  State<_HidePostForUsersSheet> createState() => _HidePostForUsersSheetState();
}

class _HidePostForUsersSheetState extends State<_HidePostForUsersSheet> {
  List<dynamic> _friends = [];
  List<dynamic> _filteredFriends = [];
  Set<String> _selectedHides = {};
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final friends = await widget.dbService.fetchFollowingProfiles();
    final hides = await widget.dbService.fetchThreadHides(widget.post.id);
    if (mounted) {
      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _selectedHides = hides.toSet();
        _isLoading = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          final name = friend.fullName.toString().toLowerCase();
          final username = friend.username.toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || username.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hide Post From",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await widget.dbService.updateThreadHides(
                        widget.post.id,
                        _selectedHides.toList(),
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Visibility settings updated")),
                        );
                      }
                    },
                    child: Text(
                      "Save",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: _filterFriends,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search friends...",
                  hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
                  : _filteredFriends.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? "You are not following any friends yet" : "No friends found matching '$_searchQuery'",
                            style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            final isSelected = _selectedHides.contains(friend.id);
                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: const Color(0xFF1E824C),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedHides.add(friend.id);
                                  } else {
                                    _selectedHides.remove(friend.id);
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                backgroundImage: (friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(friend.avatarUrl!)
                                    : null,
                                child: (friend.avatarUrl == null || friend.avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                friend.fullName,
                                style: GoogleFonts.hindSiliguri(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                "@${friend.username}",
                                style: GoogleFonts.inter(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

