import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class ReplyInputComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? avatarUrl;
  final String hintText;
  final VoidCallback onPickImage;
  final VoidCallback onOpenGif;
  final VoidCallback onOpenEmoji;
  final VoidCallback onSubmit;
  final bool isUploading;
  final bool hasSelectedMedia;
  final bool showEmojiPanel;
  final int pickerTabIndex;

  const ReplyInputComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    this.avatarUrl,
    this.hintText = "Post your reply",
    required this.onPickImage,
    required this.onOpenGif,
    required this.onOpenEmoji,
    required this.onSubmit,
    this.isUploading = false,
    this.hasSelectedMedia = false,
    this.showEmojiPanel = false,
    this.pickerTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF1E222B)
              : const Color(0xFFEFF3F4),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            CircleAvatar(
              radius: 15,
              backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 15, color: Colors.white54)
                  : null,
            ),
            const SizedBox(width: 10),

            // Text Input
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.hindSiliguri(fontSize: 14.5, color: context.textPrimary),
                maxLines: 4,
                minLines: 1,
                onTap: () {
                  // Focus tap callback
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14.5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Inline Actions (Matching X Screenshot)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                final isEnabled = (hasText || hasSelectedMedia) && !isUploading;

                if (!isEnabled) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.image_outlined, size: 21, color: context.textMuted),
                        onPressed: onPickImage,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),

                      const SizedBox(width: 2),
                      IconButton(
                        icon: Icon(
                          showEmojiPanel && pickerTabIndex == 0
                              ? Icons.keyboard_hide_outlined
                              : Icons.sentiment_satisfied_alt_outlined,
                          size: 21,
                          color: context.textMuted,
                        ),
                        onPressed: onOpenEmoji,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  );
                }

                return TextButton(
                  onPressed: onSubmit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: const Size(60, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          "Reply",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
