import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class HashtagAutocompleteOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> hashtags;
  final bool isLoading;
  final ValueChanged<String> onHashtagSelected;

  const HashtagAutocompleteOverlay({
    super.key,
    required this.hashtags,
    required this.isLoading,
    required this.onHashtagSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && hashtags.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    final accentColor = const Color(0xFF1E824C); // Brand green

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: hashtags.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final hashtag = hashtags[index];
                final name = hashtag['topic_name'] as String;
                final count = hashtag['post_count'] as int? ?? 0;

                final cleanName = name.startsWith('#') ? name : '#$name';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: accentColor.withAlpha(30),
                    child: Icon(
                      Icons.tag_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    cleanName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: context.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    "$count ${count == 1 ? 'post' : 'posts'}",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: context.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => onHashtagSelected(name),
                );
              },
            ),
    );
  }
}
