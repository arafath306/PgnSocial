import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/chat_themes.dart';
import 'swipe_to_reply.dart';
import 'chat_voice_player.dart';


class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final ChatTheme activeTheme;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final void Function(String) onOpenMedia;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.activeTheme,
    required this.onTap,
    required this.onReply,
    required this.onOpenMedia,
  });  @override
  Widget build(BuildContext context) {
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

    if (mediaType == 'theme_change') {
      final themeName = getChatThemeById(text).name;
      final who = isMe ? 'You' : 'Someone';
      final textToShow = (text != null && text.startsWith('custom:'))
          ? '$who changed the chat wallpaper'
          : '$who changed the chat theme to $themeName';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          textToShow,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: context.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final bool hasMedia = (localMediaBytes != null || (mediaUrl != null && mediaUrl.isNotEmpty)) && mediaType != 'audio';

    String timeStr = msg['time'] as String;
    if (msg['created_at'] != null) {
      try {
        final dt = DateTime.parse(msg['created_at'] as String);
        // Convert to Dhaka Time (GMT+6)
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
              : (isRead ? Colors.greenAccent : Colors.white.withValues(alpha: 0.8)))
          : (isSending
              ? Colors.white54
              : (isRead ? Colors.greenAccent : Colors.white60));

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 50),
            );

      final imageWidget = bytesOrUrl is Uint8List
          ? GestureDetector(
              onTap: onTap,
              onLongPress: onTap,
              child: image,
            )
          : GestureDetector(
              onTap: () => onOpenMedia(bytesOrUrl as String),
              onLongPress: onTap,
              child: image,
            );

      if (text == null || text.isEmpty) {
        // Overlay time row on top of image
        return ClipRRect(
          borderRadius: clipRadius,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              imageWidget,
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: buildTimeRow(overlayMode: true),
                ),
              ),
            ],
          ),
        );
      } else {
        // No overlay, just image
        return ClipRRect(
          borderRadius: clipRadius,
          child: imageWidget,
        );
      }
    }

    Widget bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply quote
        if (replyToId != null)
          Padding(
            padding: hasMedia
                ? const EdgeInsets.fromLTRB(12, 10, 12, 6)
                : EdgeInsets.zero,
            child: Container(
              margin: hasMedia ? EdgeInsets.zero : const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.15)
                    : (context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isMe
                        ? Colors.white70
                        : context.primaryAccent,
                    width: 3.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyToSender ?? 'Someone',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? Colors.white
                          : context.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyToText ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isMe
                          ? Colors.white70
                          : context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        // Media (image / GIF / audio)
        if (mediaType == 'audio') ...[
          if (mediaUrl != null && mediaUrl.isNotEmpty)
            ChatVoicePlayer(audioUrl: mediaUrl, isMe: isMe),
          if (text != null && text.isNotEmpty) const SizedBox(height: 8),
        ] else if (localMediaBytes != null) ...[
          buildImageWidget(localMediaBytes),
          if (text != null && text.isNotEmpty) const SizedBox(height: 8),
        ] else if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
          buildImageWidget(mediaUrl),
          if (text != null && text.isNotEmpty) const SizedBox(height: 8),
        ],
        // Text & Timestamp
        if (text != null && text.isNotEmpty)
          Padding(
            padding: hasMedia
                ? const EdgeInsets.fromLTRB(12, 6, 12, 4)
                : EdgeInsets.zero,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: isMe 
                        ? (activeTheme.isDark ? Colors.white : Colors.black87)
                        : context.textPrimary,
                    height: 1.4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: buildTimeRow(overlayMode: false),
                ),
              ],
            ),
          )
        else if (!hasMedia)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, left: 16),
              child: buildTimeRow(overlayMode: false),
            ),
          ),
      ],
    );

    if (!hasMedia) {
      bubbleContent = IntrinsicWidth(child: bubbleContent);
    }

    return SwipeToReply(
      onReply: onReply,
      isMe: isMe,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.75).clamp(200.0, 450.0)),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onTap,
            child: Container(
              padding: hasMedia
                  ? EdgeInsets.zero
                  : const EdgeInsets.fromLTRB(12, 8, 8, 4),
              decoration: BoxDecoration(
                color: isMe
                    ? (activeTheme.gradientColors == null ? activeTheme.primaryColor : null)
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
                border: isMe
                    ? null
                    : Border.all(color: context.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: bubbleContent,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageShimmerPlaceholder extends StatefulWidget {
  const _ImageShimmerPlaceholder();

  @override
  State<_ImageShimmerPlaceholder> createState() => _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<_ImageShimmerPlaceholder> with SingleTickerProviderStateMixin {
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
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
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

// â”€â”€â”€ Chat Composer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Completely isolated widget. Only rebuilds when its own state changes,
// NOT when messages arrive. The input field is local â€” no external setState.