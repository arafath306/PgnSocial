import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';

class PinnedMessageBanner extends StatelessWidget {
  final Map<String, dynamic> message;
  final int currentIndex;
  final int totalPinned;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const PinnedMessageBanner({
    super.key,
    required this.message,
    this.currentIndex = 1,
    this.totalPinned = 1,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final text = message['text'] as String? ?? '';
    final mediaType = message['media_type'] as String?;
    final mediaUrl = message['media_url'] as String?;

    String previewText = text;
    if (previewText.isEmpty) {
      if (mediaType == 'audio') {
        previewText = '🎙️ Voice message';
      } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
        previewText = '📷 Photo';
      } else {
        previewText = 'Pinned message';
      }
    }

    final title = totalPinned > 1
        ? 'Pinned Message ($currentIndex/$totalPinned)'
        : 'Pinned Message';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: context.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Accent left bar indicator
                Container(
                  width: 3.5,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.primaryAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                // Icon
                Icon(
                  Icons.push_pin_rounded,
                  color: context.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                // Content preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unpin button
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  tooltip: 'Unpin message',
                  onPressed: onUnpin,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
