import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/chat_themes.dart';
import 'swipe_to_reply.dart';
import 'chat_voice_player.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final ChatTheme activeTheme;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final void Function(String) onOpenMedia;
  final void Function(String emoji)? onToggleReaction;
  final VoidCallback? onDoubleTap;
  final String? currentUserId;
  final bool isHighlighted;
  final String? searchQuery;
  final double marginBottom;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.activeTheme,
    required this.onTap,
    required this.onReply,
    required this.onOpenMedia,
    this.onToggleReaction,
    this.onDoubleTap,
    this.currentUserId,
    this.isHighlighted = false,
    this.searchQuery,
    this.marginBottom = 10.0,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  bool _showHeartPop = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.35, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
    ]).animate(_heartAnimController);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeartPop = false);
      }
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapHeart() {
    setState(() => _showHeartPop = true);
    _heartAnimController.forward(from: 0.0);
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
    } else if (widget.onToggleReaction != null) {
      widget.onToggleReaction!('❤️');
    }
  }

  Map<String, String> _parseReactions() {
    final raw = widget.msg['reactions'];
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final activeTheme = widget.activeTheme;
    final onTap = widget.onTap;
    final onReply = widget.onReply;
    final onOpenMedia = widget.onOpenMedia;
    final marginBottom = widget.marginBottom;

    final bool isMe = msg['isMe'] as bool;
    final String? mediaUrl = msg['media_url'] as String?;
    final localMediaBytes = msg['local_media_bytes'];
    final bool isRead = msg['is_read'] as bool? ?? false;
    final bool isSending = msg['is_sending'] as bool? ?? false;
    final String? replyToId = msg['reply_to_id'] as String?;
    final String? replyToText = msg['reply_to_text'] as String?;
    final String? replyToSender = msg['reply_to_sender'] as String?;
    final String? mediaType = msg['media_type'] as String?;
    final String? text = msg['text'] as String?;

    if (mediaType == 'theme_change' || mediaType == 'wallpaper_change') {
      final who = isMe ? 'You' : 'Someone';
      String textToShow;
      IconData iconData = Icons.palette_rounded;

      if (mediaType == 'wallpaper_change') {
        final url = msg['media_url'] as String?;
        if (url == 'none') {
          textToShow = '$who removed the chat wallpaper';
          iconData = Icons.hide_image_outlined;
        } else {
          textToShow = '$who changed the chat wallpaper';
          iconData = Icons.wallpaper_rounded;
        }
      } else {
        final themeName = getChatThemeById(text).name;
        if (text != null && text.startsWith('custom:')) {
          textToShow = '$who changed the chat wallpaper';
          iconData = Icons.wallpaper_rounded;
        } else {
          textToShow = '$who changed the theme to $themeName';
          iconData = Icons.palette_rounded;
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.border.withValues(alpha: 0.5),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 14, color: context.primaryAccent),
              const SizedBox(width: 6),
              Text(
                textToShow,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool hasMedia = (localMediaBytes != null ||
            (mediaUrl != null && mediaUrl.isNotEmpty)) &&
        mediaType != 'audio';

    String timeStr = msg['time'] as String? ?? '';
    if (msg['created_at'] != null) {
      try {
        final dt = DateTime.parse(msg['created_at'] as String);
        final dhakaTime = dt.toUtc().add(const Duration(hours: 6));
        final hour24 = dhakaTime.hour;
        final minute = dhakaTime.minute.toString().padLeft(2, '0');
        final period = hour24 >= 12 ? 'PM' : 'AM';
        int hour12 = hour24 % 12;
        if (hour12 == 0) hour12 = 12;
        timeStr = '$hour12:$minute $period';
      } catch (e) {
        debugPrint('[MessageBubble] Error parsing time: $e');
      }
    }

    Widget buildTimeRow({required bool overlayMode}) {
      final textStyle = GoogleFonts.inter(
        fontSize: overlayMode ? 9.5 : 10,
        color: overlayMode
            ? Colors.white
            : (isMe ? Colors.white60 : context.textMuted),
      );

      final iconColor = overlayMode
          ? (isSending
              ? Colors.white.withValues(alpha: 0.5)
              : (isRead
                  ? Colors.greenAccent
                  : Colors.white.withValues(alpha: 0.8)))
          : (isSending
              ? Colors.white54
              : (isRead ? Colors.greenAccent : Colors.white60));

      final bool isPinned = msg['is_pinned'] as bool? ?? false;

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPinned) ...[
            Icon(
              Icons.push_pin_rounded,
              size: 11,
              color: overlayMode
                  ? Colors.white.withValues(alpha: 0.9)
                  : (isMe ? Colors.white70 : context.primaryAccent),
            ),
            const SizedBox(width: 3),
          ],
          Text(timeStr, style: textStyle),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              isSending
                  ? Icons.schedule_rounded
                  : (isRead ? Icons.done_all : Icons.done),
              size: 12,
              color: iconColor,
            ),
          ],
        ],
      );
    }

    Widget buildImageWidget(dynamic bytesOrUrl) {
      final clipRadius = BorderRadius.only(
        topLeft: replyToId == null ? const Radius.circular(16) : Radius.zero,
        topRight: replyToId == null ? const Radius.circular(16) : Radius.zero,
        bottomLeft: (text == null || text.isEmpty)
            ? (isMe ? const Radius.circular(16) : Radius.zero)
            : Radius.zero,
        bottomRight: (text == null || text.isEmpty)
            ? (isMe ? Radius.zero : const Radius.circular(16))
            : Radius.zero,
      );

      final image = bytesOrUrl is Uint8List
          ? Image.memory(
              bytesOrUrl,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: bytesOrUrl as String,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              placeholder: (context, url) => const _ImageShimmerPlaceholder(),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 240,
                color: Colors.black26,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white54, size: 32),
                ),
              ),
            );

      final isOnlyImage = (text == null || text.isEmpty);

      return GestureDetector(
        onTap: () {
          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            onOpenMedia(mediaUrl);
          }
        },
        child: ClipRRect(
          borderRadius: clipRadius,
          child: Stack(
            children: [
              image,
              if (isOnlyImage)
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: buildTimeRow(overlayMode: true),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget buildReplyQuoteHeader() {
      if (replyToId == null) return const SizedBox.shrink();

      final isDark = context.isDarkMode;
      final quoteBg = isMe
          ? Colors.black.withValues(alpha: 0.15)
          : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04));

      final barColor = isMe ? Colors.white70 : context.primaryAccent;
      final nameColor = isMe ? Colors.white : context.primaryAccent;
      final bodyColor = isMe ? Colors.white70 : context.textSecondary;

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: quoteBg,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: barColor, width: 3)),
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
                color: nameColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              replyToText ?? '',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: bodyColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    Widget buildVoicePlayerWidget(String url) {
      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatVoicePlayer(
            audioUrl: url,
            isMe: isMe,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: buildTimeRow(overlayMode: false),
          ),
        ],
      );
    }

    Widget buildTextContentWidget(String bodyText) {
      final baseStyle = GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.25,
        color: isMe ? Colors.white : context.textPrimary,
        fontWeight: FontWeight.w400,
      );

      Widget textChild;
      final query = widget.searchQuery?.trim().toLowerCase();

      if (query != null && query.isNotEmpty && bodyText.toLowerCase().contains(query)) {
        final List<TextSpan> spans = [];
        final lower = bodyText.toLowerCase();
        int start = 0;

        while (true) {
          final index = lower.indexOf(query, start);
          if (index == -1) {
            spans.add(TextSpan(text: bodyText.substring(start), style: baseStyle));
            break;
          }
          if (index > start) {
            spans.add(TextSpan(text: bodyText.substring(start, index), style: baseStyle));
          }
          spans.add(
            TextSpan(
              text: bodyText.substring(index, index + query.length),
              style: baseStyle.copyWith(
                backgroundColor: isMe
                    ? Colors.amberAccent.withValues(alpha: 0.8)
                    : Colors.amber.withValues(alpha: 0.4),
                color: isMe ? Colors.black87 : context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          start = index + query.length;
        }

        textChild = Text.rich(TextSpan(children: spans));
      } else {
        textChild = Text(bodyText, style: baseStyle);
      }

      return Padding(
        padding: hasMedia
            ? const EdgeInsets.fromLTRB(10, 6, 8, 4)
            : const EdgeInsets.only(right: 4, bottom: 2),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: textChild,
            ),
            const SizedBox(height: 2),
            buildTimeRow(overlayMode: false),
          ],
        ),
      );
    }

    Widget bubbleContent;

    if (mediaType == 'audio' && mediaUrl != null && mediaUrl.isNotEmpty) {
      bubbleContent = buildVoicePlayerWidget(mediaUrl);
    } else {
      bubbleContent = Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildReplyQuoteHeader(),
          if (localMediaBytes != null) buildImageWidget(localMediaBytes),
          if (localMediaBytes == null &&
              mediaUrl != null &&
              mediaUrl.isNotEmpty)
            buildImageWidget(mediaUrl),
          if (text != null && text.isNotEmpty) buildTextContentWidget(text),
        ],
      );
    }

    final reactions = _parseReactions();
    final hasReactions = reactions.isNotEmpty;
    final effectiveMarginBottom = marginBottom + (hasReactions ? 12.0 : 0.0);

    return SwipeToReply(
      onReply: onReply,
      isMe: isMe,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: effectiveMarginBottom),
          constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.75)
                  .clamp(80.0, 450.0)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onTap,
                onLongPress: onTap,
                onDoubleTap: _triggerDoubleTapHeart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  padding: hasMedia
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(12, 8, 8, 4),
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
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                      bottomRight: isMe
                          ? const Radius.circular(0)
                          : const Radius.circular(16),
                    ),
                    border: widget.isHighlighted
                        ? Border.all(color: context.primaryAccent, width: 2.0)
                        : (isMe
                            ? null
                            : Border.all(color: context.border, width: 0.8)),
                    boxShadow: [
                      if (widget.isHighlighted)
                        BoxShadow(
                          color: context.primaryAccent.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      bubbleContent,
                      if (_showHeartPop)
                        FadeTransition(
                          opacity: _heartOpacity,
                          child: ScaleTransition(
                            scale: _heartScale,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: const Text(
                                '❤️',
                                style: TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (hasReactions)
                Positioned(
                  bottom: -10,
                  right: isMe ? 8 : null,
                  left: isMe ? null : 8,
                  child: _buildReactionsBadge(context, reactions, isMe),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionsBadge(
      BuildContext context, Map<String, String> reactions, bool isMe) {
    final isDark = context.isDarkMode;
    final myUid = widget.currentUserId;
    final hasMyReaction = myUid != null && reactions.containsKey(myUid);

    // Count frequency of each emoji
    final Map<String, int> emojiCounts = {};
    for (final emoji in reactions.values) {
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
    }

    // Top 3 distinct emojis
    final topEmojis = emojiCounts.keys.take(3).toList();
    final totalCount = reactions.length;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasMyReaction
                ? context.primaryAccent.withValues(alpha: 0.8)
                : context.border.withValues(alpha: 0.6),
            width: hasMyReaction ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...topEmojis.map((emoji) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Text(emoji, style: const TextStyle(fontSize: 13)),
                )),
            if (totalCount > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$totalCount',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasMyReaction
                      ? context.primaryAccent
                      : context.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageShimmerPlaceholder extends StatefulWidget {
  const _ImageShimmerPlaceholder();

  @override
  State<_ImageShimmerPlaceholder> createState() =>
      _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<_ImageShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: double.infinity,
          height: 240,
          color: baseColor,
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.white38, size: 36),
          ),
        ),
      ),
    );
  }
}
