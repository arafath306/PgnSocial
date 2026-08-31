import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/chat_themes.dart';
import '../utils/app_theme.dart';

class ThemePickerSheet extends StatefulWidget {
  final String currentThemeId;
  final Function(String themeId) onThemeSelected;
  final Function(XFile image) onCustomWallpaperSelected;
  final VoidCallback onRemoveWallpaper;

  const ThemePickerSheet({
    super.key,
    required this.currentThemeId,
    required this.onThemeSelected,
    required this.onCustomWallpaperSelected,
    required this.onRemoveWallpaper,
  });

  @override
  State<ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<ThemePickerSheet> with SingleTickerProviderStateMixin {
  late String _selectedThemeId;
  int _selectedFilterIndex = 0; // 0: All, 1: Gradients, 2: Solids

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.currentThemeId;
  }

  Future<void> _pickCustomImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        if (!context.mounted) return;
        Navigator.pop(context);
        widget.onCustomWallpaperSelected(image);
      }
    } catch (e) {
      debugPrint('Error picking custom wallpaper: $e');
    }
  }

  List<ChatTheme> get _filteredThemes {
    if (_selectedFilterIndex == 1) {
      return availableChatThemes.where((t) => t.gradientColors != null).toList();
    } else if (_selectedFilterIndex == 2) {
      return availableChatThemes.where((t) => t.gradientColors == null).toList();
    }
    return availableChatThemes;
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = getChatThemeById(_selectedThemeId);
    final isDarkSheet = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Title & Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Theme & Style',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customize background and message colors',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: context.primaryAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ⚡ Live Preview Card (Mock Interactive Message Bubble)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 136,
              width: double.infinity,
              decoration: BoxDecoration(
                color: activeTheme.gradientColors != null
                    ? null
                    : activeTheme.primaryColor.withValues(alpha: isDarkSheet ? 0.14 : 0.07),
                gradient: activeTheme.gradientColors != null
                    ? LinearGradient(
                        colors: activeTheme.gradientColors!
                            .map((c) => c.withValues(alpha: isDarkSheet ? 0.22 : 0.1))
                            .toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border.withValues(alpha: 0.7), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Incoming Message Bubble
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkSheet ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(color: context.border.withValues(alpha: 0.6), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Text(
                        "Hey! Loving this sleek theme ✨",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Outgoing Message Bubble with active theme applied
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: activeTheme.gradientColors == null ? activeTheme.primaryColor : null,
                        gradient: activeTheme.gradientColors != null
                            ? LinearGradient(
                                colors: activeTheme.gradientColors!,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (activeTheme.gradientColors == null 
                                    ? activeTheme.primaryColor 
                                    : activeTheme.gradientColors!.first)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        "Looks like a billion dollar app! 🚀",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activeTheme.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Filter Segment Chips (All / Gradients / Solids)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildSegmentChip(0, 'All (${availableChatThemes.length})'),
                const SizedBox(width: 8),
                _buildSegmentChip(1, 'Gradients'),
                const SizedBox(width: 8),
                _buildSegmentChip(2, 'Solids'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Palette List
          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filteredThemes.length,
              itemBuilder: (context, index) {
                final theme = _filteredThemes[index];
                final isSelected = theme.id == _selectedThemeId;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedThemeId = theme.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 56 : 50,
                          height: isSelected ? 56 : 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.gradientColors == null ? theme.primaryColor : null,
                            gradient: theme.gradientColors != null
                                ? LinearGradient(
                                    colors: theme.gradientColors!,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            border: isSelected
                                ? Border.all(color: context.primaryAccent, width: 3.5)
                                : Border.all(color: context.border.withValues(alpha: 0.6), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? context.primaryAccent.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.08),
                                blurRadius: isSelected ? 10 : 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: theme.isDark ? Colors.white : Colors.black87,
                                  size: 22,
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 68,
                          child: Text(
                            theme.name,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: isSelected ? context.primaryAccent : context.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Apply Theme Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  widget.onThemeSelected(_selectedThemeId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: context.primaryAccent.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Apply Theme',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Wallpaper Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Wallpapers & Backgrounds',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Wallpapers Actions Container Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkSheet ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickCustomImage(context);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.image_outlined, color: context.primaryAccent, size: 18),
                    ),
                    title: Text(
                      'Set Custom Wallpaper',
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Choose a background photo from gallery',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 18),
                  ),
                  Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
                  ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      widget.onRemoveWallpaper();
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hide_image_outlined, color: Colors.red, size: 18),
                    ),
                    title: Text(
                      'Remove Custom Wallpaper',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Reset to clean theme background',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.primaryAccent
                : context.border.withValues(alpha: 0.6),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? context.primaryAccent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
