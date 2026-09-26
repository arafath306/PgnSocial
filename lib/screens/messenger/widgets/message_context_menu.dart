import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../utils/app_theme.dart';
import '../../../utils/chat_themes.dart';
import 'reaction_bar.dart';

/// Shows the Telegram-identical context menu anchored to the tapped message bubble.
Future<void> showTelegramMessageContextMenu({
  required BuildContext context,
  required Map<String, dynamic> msg,
  required Rect? bubbleRect,
  required ChatTheme activeTheme,
  required String? currentUserId,
  required void Function(String emoji) onSelectReaction,
  required VoidCallback onOpenMoreEmojis,
  required VoidCallback onReply,
  required VoidCallback onTranslate,
  required VoidCallback onCopy,
  VoidCallback? onEdit,
  required VoidCallback onPin,
  required VoidCallback onDelete,
  VoidCallback? onReport,
  VoidCallback? onSaveMedia,
  required bool isPinned,
  bool? isOtherUserActive,
  DateTime? otherUserLastSeen,
  bool? isDelivered,
  bool? isEdited,
}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return TelegramMessageContextMenu(
        msg: msg,
        bubbleRect: bubbleRect,
        activeTheme: activeTheme,
        currentUserId: currentUserId,
        onSelectReaction: onSelectReaction,
        onOpenMoreEmojis: onOpenMoreEmojis,
        onReply: onReply,
        onTranslate: onTranslate,
        onCopy: onCopy,
        onEdit: onEdit,
        onPin: onPin,
        onDelete: onDelete,
        onReport: onReport,
        onSaveMedia: onSaveMedia,
        isPinned: isPinned,
        isOtherUserActive: isOtherUserActive,
        otherUserLastSeen: otherUserLastSeen,
        isDelivered: isDelivered,
        isEdited: isEdited,
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}

class TelegramMessageContextMenu extends StatefulWidget {
  final Map<String, dynamic> msg;
  final Rect? bubbleRect;
  final ChatTheme activeTheme;
  final String? currentUserId;
  final void Function(String emoji) onSelectReaction;
  final VoidCallback onOpenMoreEmojis;
  final VoidCallback onReply;
  final VoidCallback onTranslate;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onSaveMedia;
  final bool isPinned;
  final bool? isOtherUserActive;
  final DateTime? otherUserLastSeen;
  final bool? isDelivered;
  final bool? isEdited;

  const TelegramMessageContextMenu({
    super.key,
    required this.msg,
    required this.bubbleRect,
    required this.activeTheme,
    required this.currentUserId,
    required this.onSelectReaction,
    required this.onOpenMoreEmojis,
    required this.onReply,
    required this.onTranslate,
    required this.onCopy,
    this.onEdit,
    required this.onPin,
    required this.onDelete,
    this.onReport,
    this.onSaveMedia,
    required this.isPinned,
    this.isOtherUserActive,
    this.otherUserLastSeen,
    this.isDelivered,
    this.isEdited,
  });

  @override
  State<TelegramMessageContextMenu> createState() =>
      _TelegramMessageContextMenuState();
}

class _TelegramMessageContextMenuState extends State<TelegramMessageContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Quick reaction emojis matching the screenshot: ❤️ 👍 😆 👀 😢
  static const List<String> _quickReactions = [
    '❤️',
    '👍',
    '😆',
    '👀',
    '😢',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTo12Hr(DateTime dt) {
    final hour24 = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:$m $period';
  }

  String _formatStatusTime(Map<String, dynamic> msg, String prefix) {
    DateTime? dt;
    if (msg['created_at'] != null) {
      try {
        dt = DateTime.parse(msg['created_at'] as String).toLocal();
      } catch (_) {}
    }
    if (dt == null) {
      final raw = msg['time'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final parts = raw.split(':');
        if (parts.length == 2 && !raw.contains('AM') && !raw.contains('PM')) {
          final h = int.tryParse(parts[0].trim());
          final m = int.tryParse(parts[1].trim());
          if (h != null && m != null) {
            final period = h >= 12 ? 'PM' : 'AM';
            int hour12 = h % 12;
            if (hour12 == 0) hour12 = 12;
            final mStr = m.toString().padLeft(2, '0');
            return '$prefix at $hour12:$mStr $period';
          }
        }
        return '$prefix at $raw';
      }
      return prefix;
    }

    final timeStr = _formatTo12Hr(dt);

    final now = DateTime.now();
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;

    if (diffDays == 0) {
      return '$prefix at $timeStr';
    } else if (diffDays == 1) {
      return '$prefix yesterday at $timeStr';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months[dt.month - 1];
      return '$prefix on ${dt.day} $month at $timeStr';
    }
  }

  _MessageStatusInfo _getMessageStatusInfo(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'] as bool? ?? false;
    final bool isSending = msg['is_sending'] as bool? ?? false;
    final bool isRead = msg['is_read'] as bool? ?? false;
    final String id = msg['id']?.toString() ?? '';
    final bool isTemp = id.startsWith('temp_');

    if (!isMe) {
      final timeStr = _formatStatusTime(msg, 'Received');
      return _MessageStatusInfo(
        text: timeStr,
        icon: Icons.done_all_rounded,
        color: const Color(0xFF7E8E9F),
        textColor: const Color(0xFF7E8E9F),
      );
    }

    if (isSending || isTemp) {
      return const _MessageStatusInfo(
        text: 'Sending...',
        icon: Icons.schedule_rounded,
        color: Color(0xFF94A3B8),
        textColor: Color(0xFF94A3B8),
        iconSize: 13.5,
      );
    }

    if (isRead) {
      final timeStr = _formatStatusTime(msg, 'Seen');
      return _MessageStatusInfo(
        text: timeStr,
        icon: Icons.done_all_rounded,
        color: const Color(0xFF38BDF8),
        textColor: const Color(0xFF38BDF8),
        iconSize: 16.0,
      );
    }

    // Determine Delivered vs Sent
    bool isDelivered =
        widget.isDelivered ?? (msg['is_delivered'] as bool? ?? false);
    if (!isDelivered && widget.isOtherUserActive == true) {
      isDelivered = true;
    }
    if (!isDelivered && widget.otherUserLastSeen != null) {
      DateTime? msgCreatedAt;
      if (msg['created_at'] != null) {
        msgCreatedAt = DateTime.tryParse(msg['created_at'] as String);
      }
      if (msgCreatedAt != null &&
          widget.otherUserLastSeen!.isAfter(msgCreatedAt)) {
        isDelivered = true;
      }
    }
    if (!isDelivered && msg['created_at'] != null) {
      final msgCreatedAt = DateTime.tryParse(msg['created_at'] as String);
      if (msgCreatedAt != null &&
          DateTime.now().difference(msgCreatedAt.toLocal()).inSeconds >= 45) {
        isDelivered = true;
      }
    }

    if (isDelivered) {
      final timeStr = _formatStatusTime(msg, 'Delivered');
      return _MessageStatusInfo(
        text: timeStr,
        icon: Icons.done_all_rounded,
        color: const Color(0xFF94A3B8),
        textColor: const Color(0xFFCBD5E1),
        iconSize: 16.0,
      );
    } else {
      final timeStr = _formatStatusTime(msg, 'Sent');
      return _MessageStatusInfo(
        text: timeStr,
        icon: Icons.check_rounded,
        color: const Color(0xFF94A3B8),
        textColor: const Color(0xFF94A3B8),
        iconSize: 15.0,
      );
    }
  }

  Widget _buildStatusHeader(BuildContext context) {
    final status = _getMessageStatusInfo(widget.msg);
    final bool isEdited = widget.isEdited ??
        (widget.msg['is_edited'] == true ||
            widget.msg['edited_at'] != null ||
            (widget.msg['text'] is String &&
                (widget.msg['text'] as String).contains('"is_edited":true')));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Sent / Delivered / Seen status with icon and timestamp in 12hr
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.icon,
                  size: status.iconSize,
                  color: status.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    status.text,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: status.textColor ?? const Color(0xFF7E8E9F),
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Right side (other side of sent/delivery/seen): Edited indicator
          if (isEdited) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 3.5),
                Text(
                  'Edited',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _closeWith(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;
    final bool isMe = widget.msg['isMe'] as bool? ?? false;
    final String? text = widget.msg['text'] as String?;
    final String? mediaUrl = widget.msg['media_url'] as String?;
    final bool hasText = text != null && text.trim().isNotEmpty;
    final bool hasMedia = mediaUrl != null && mediaUrl.isNotEmpty;

    // Dimensions
    const double menuWidth = 255.0;
    const double reactionPillHeight = 46.0;
    const double reactionPillWidth = 240.0;

    // Estimate menu height: header (38) + items (~44 each)
    int itemCount = 1; // Reply
    if (hasText) itemCount += 2; // Translate, Copy message text
    if (widget.onEdit != null) itemCount += 1; // Edit
    itemCount += 1; // Pin
    itemCount += 1; // Delete for me
    if (widget.onReport != null) itemCount += 1; // Report
    if (widget.onSaveMedia != null) itemCount += 1; // Save to gallery
    final double estimatedMenuHeight = 38.0 + (itemCount * 44.0) + 12.0;

    // Anchor calculation
    final Rect? rawRect = widget.bubbleRect;
    double bubbleX;
    double bubbleY;
    double bubbleWidth;
    double bubbleHeight;

    if (rawRect != null) {
      bubbleWidth = rawRect.width.clamp(100.0, screenSize.width * 0.78);
      bubbleHeight = rawRect.height;
      bubbleX = rawRect.left;
      bubbleY = rawRect.top;
    } else {
      // Fallback center
      bubbleWidth = (screenSize.width * 0.65).clamp(140.0, 320.0);
      bubbleHeight = 52.0;
      bubbleX = isMe
          ? (screenSize.width - bubbleWidth - 16)
          : 16;
      bubbleY = screenSize.height * 0.4;
    }

    // Ensure entire cluster (pill + bubble + menu) fits on screen vertically
    final double minTop = screenPadding.top + reactionPillHeight + 16;
    final double maxBottom =
        screenSize.height - screenPadding.bottom - estimatedMenuHeight - 16;

    double adjustedBubbleY = bubbleY;
    if (adjustedBubbleY + bubbleHeight > maxBottom) {
      adjustedBubbleY = (maxBottom - bubbleHeight).clamp(minTop, screenSize.height - 120);
    }
    if (adjustedBubbleY < minTop) {
      adjustedBubbleY = minTop;
    }

    // Horizontal placement
    double menuLeft;
    double reactionLeft;

    if (isMe) {
      // Right-aligned to bubble
      final double rightEdge = bubbleX + bubbleWidth;
      menuLeft = (rightEdge - menuWidth).clamp(12.0, screenSize.width - menuWidth - 12);
      reactionLeft = (rightEdge - reactionPillWidth).clamp(12.0, screenSize.width - reactionPillWidth - 12);
    } else {
      // Left-aligned to bubble
      menuLeft = bubbleX.clamp(12.0, screenSize.width - menuWidth - 12);
      reactionLeft = bubbleX.clamp(12.0, screenSize.width - reactionPillWidth - 12);
    }

    final double pillTop = adjustedBubbleY - reactionPillHeight - 8.0;
    final double menuTop = adjustedBubbleY + bubbleHeight + 8.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 1. Focused Bubble (Highlight in place)
              Positioned(
                left: bubbleX,
                top: adjustedBubbleY,
                width: bubbleWidth,
                height: bubbleHeight,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildFocusedBubble(context, isMe, text, hasMedia),
                ),
              ),

              // 2. Floating Reaction Pill (Above Bubble)
              Positioned(
                left: reactionLeft,
                top: pillTop,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildReactionPill(context),
                ),
              ),

              // 3. Action Menu Card (Below Bubble)
              Positioned(
                left: menuLeft,
                top: menuTop,
                width: menuWidth,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildActionMenuCard(
                    context,
                    hasText: hasText,
                    hasMedia: hasMedia,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Replica of the message bubble in focused state without timestamp
  Widget _buildFocusedBubble(
      BuildContext context, bool isMe, String? text, bool hasMedia) {
    final activeTheme = widget.activeTheme;
    final replyToText = widget.msg['reply_to_text'] as String?;
    final replyToSender = widget.msg['reply_to_sender'] as String?;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isMe
              ? (activeTheme.gradientColors == null
                  ? activeTheme.primaryColor
                  : null)
              : context.cardBg,
          gradient: (isMe && activeTheme.gradientColors != null)
              ? LinearGradient(
                  colors: activeTheme.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            if (replyToText != null && replyToText.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(
                      color: isMe ? Colors.white70 : context.primaryAccent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      replyToSender ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isMe ? Colors.white : context.primaryAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      replyToText,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isMe ? Colors.white70 : context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            if (text != null && text.isNotEmpty)
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.25,
                  color: isMe ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (hasMedia && (text == null || text.isEmpty))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_rounded,
                      size: 18, color: isMe ? Colors.white70 : context.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : context.textPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

  /// Floating reaction pill: ❤️ 👍 😆 👀 😢 +
  Widget _buildReactionPill(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2431),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._quickReactions.map((emoji) {
              return _ReactionEmojiItem(
                emoji: emoji,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _closeWith(() => widget.onSelectReaction(emoji));
                },
              );
            }),
            const SizedBox(width: 4),
            // + button to open full emoji picker
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _closeWith(widget.onOpenMoreEmojis);
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: Color(0xFFD6DFE8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action menu card matching Telegram's exact design and typography
  Widget _buildActionMenuCard(
    BuildContext context, {
    required bool hasText,
    required bool hasMedia,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2431),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sent / Delivered / Seen status with icon and timestamp
            _buildStatusHeader(context),

            // 1. Reply
            _MenuItem(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () => _closeWith(widget.onReply),
            ),

            // 2. Translate (if message has text)
            if (hasText)
              _MenuItem(
                icon: Icons.g_translate_rounded,
                label: 'Translate',
                onTap: () => _closeWith(widget.onTranslate),
              ),

            // 3. Copy message text
            if (hasText)
              _MenuItem(
                icon: Icons.copy_rounded,
                label: 'Copy message text',
                onTap: () => _closeWith(widget.onCopy),
              ),

            // 4. Edit (if own message with text)
            if (widget.onEdit != null)
              _MenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _closeWith(widget.onEdit!),
              ),

            // 5. Pin / Unpin
            _MenuItem(
              icon: Icons.push_pin_outlined,
              label: widget.isPinned ? 'Unpin message' : 'Pin',
              onTap: () => _closeWith(widget.onPin),
            ),

            // 6. Delete
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              isDestructive: true,
              onTap: () => _closeWith(widget.onDelete),
            ),

            // 7. Report (if other's message)
            if (widget.onReport != null)
              _MenuItem(
                icon: Icons.flag_outlined,
                label: 'Report',
                onTap: () => _closeWith(widget.onReport!),
              ),

            // 8. Save to gallery (if media)
            if (widget.onSaveMedia != null)
              _MenuItem(
                icon: Icons.download_rounded,
                label: 'Save to gallery',
                onTap: () => _closeWith(widget.onSaveMedia!),
              ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ReactionEmojiItem extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionEmojiItem({
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_ReactionEmojiItem> createState() => _ReactionEmojiItemState();
}

class _ReactionEmojiItemState extends State<_ReactionEmojiItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.22 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: renderReactionEmoji(widget.emoji, size: 24),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF5252) : const Color(0xFFDDE4EC);
    final textColor = isDestructive ? const Color(0xFFFF5252) : Colors.white;

    return InkWell(
      onTap: onTap,
      splashColor: (isDestructive ? Colors.red : Colors.white).withValues(alpha: 0.08),
      highlightColor: (isDestructive ? Colors.red : Colors.white).withValues(alpha: 0.04),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Telegram-style translation bottom sheet
Future<void> showTelegramTranslationSheet(
  BuildContext context, {
  required String text,
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1B2431),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) => _TranslationSheetContent(originalText: text),
  );
}

class _TranslationSheetContent extends StatefulWidget {
  final String originalText;

  const _TranslationSheetContent({required this.originalText});

  @override
  State<_TranslationSheetContent> createState() =>
      _TranslationSheetContentState();
}

class _TranslationSheetContentState extends State<_TranslationSheetContent> {
  bool _isLoading = true;
  String? _translatedText;
  String? _errorMessage;
  String _targetLangName = 'English';

  @override
  void initState() {
    super.initState();
    _performTranslation();
  }

  Future<void> _performTranslation() async {
    try {
      // If original text has Bengali characters, translate to English, else Bengali
      final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(widget.originalText);
      final targetLang = hasBengali ? 'en' : 'bn';
      _targetLangName = hasBengali ? 'English' : 'Bengali';

      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(widget.originalText)}',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final buffer = StringBuffer();
          for (final segment in decoded[0]) {
            if (segment is List && segment.isNotEmpty && segment[0] != null) {
              buffer.write(segment[0].toString());
            }
          }
          if (mounted) {
            setState(() {
              _translatedText = buffer.toString();
              _isLoading = false;
            });
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not translate this message.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Translation service unavailable offline.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.g_translate_rounded,
                      size: 20,
                      color: Color(0xFF2481CC),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Translation ($_targetLangName)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Original text card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original text',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF7E8E9F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.originalText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Translated text card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2481CC).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2481CC).withValues(alpha: 0.25),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Color(0xFF2481CC)),
                          ),
                        ),
                      ),
                    )
                  : (_errorMessage != null
                      ? Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Translated text',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF2481CC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _translatedText ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )),
            ),
            const SizedBox(height: 18),

            // Copy Translation button
            if (_translatedText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _translatedText!));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Translation copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copy Translation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2481CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageStatusInfo {
  final String text;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final double iconSize;

  const _MessageStatusInfo({
    required this.text,
    required this.icon,
    required this.color,
    this.textColor,
    this.iconSize = 14.0,
  });
}
