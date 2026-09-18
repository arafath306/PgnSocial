import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';

enum ChatFilter { all, unread, pinned }

class ChatFilterChips extends StatelessWidget {
  final ChatFilter selectedFilter;
  final int unreadCount;
  final int pinnedCount;
  final ValueChanged<ChatFilter> onFilterSelected;

  const ChatFilterChips({
    super.key,
    required this.selectedFilter,
    required this.unreadCount,
    required this.pinnedCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'All',
            filter: ChatFilter.all,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Unread',
            badgeCount: unreadCount,
            filter: ChatFilter.unread,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Pinned',
            badgeCount: pinnedCount,
            filter: ChatFilter.pinned,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required ChatFilter filter,
    required bool isDark,
    int badgeCount = 0,
  }) {
    final isSelected = selectedFilter == filter;
    final primaryColor = context.textPrimary;

    return InkWell(
      onTap: () => onFilterSelected(filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF21262D) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : primaryColor,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
