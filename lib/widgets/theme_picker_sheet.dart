import 'package:flutter/material.dart';
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

class _ThemePickerSheetState extends State<ThemePickerSheet> {
  late String _selectedThemeId;

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

  @override
  Widget build(BuildContext context) {
    final activeTheme = getChatThemeById(_selectedThemeId);
    final isDarkSheet = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
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
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Customize Chat',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ⚡ Live Preview Card (Mini Mock Chat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: activeTheme.gradientColors != null
                    ? null
                    : activeTheme.primaryColor.withValues(alpha: isDarkSheet ? 0.12 : 0.06),
                gradient: activeTheme.gradientColors != null
                    ? LinearGradient(
                        colors: activeTheme.gradientColors!
                            .map((c) => c.withValues(alpha: isDarkSheet ? 0.18 : 0.08))
                            .toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border.withValues(alpha: 0.6), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Incoming Message Bubble
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkSheet ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Text(
                        "Hey! Do you like this chat theme? 🤔",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Outgoing Message Bubble
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (activeTheme.gradientColors == null 
                                    ? activeTheme.primaryColor 
                                    : activeTheme.gradientColors!.first)
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        "Yes! It looks absolutely 10/10! 😍",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: activeTheme.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable Predefined Themes List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select Chat Theme',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: availableChatThemes.length,
              itemBuilder: (context, index) {
                final theme = availableChatThemes[index];
                final isSelected = theme.id == _selectedThemeId;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThemeId = theme.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
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
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSelected ? context.primaryAccent : context.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Apply Theme Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onThemeSelected(_selectedThemeId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: context.primaryAccent.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Apply Selected Theme',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Wallpaper Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Wallpapers & Backgrounds',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Wallpapers Actions Container Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkSheet ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => _pickCustomImage(context),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.photo_library_outlined, color: context.primaryAccent, size: 18),
                    ),
                    title: Text(
                      'Custom Wallpaper',
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Choose a photo from your gallery',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 18),
                  ),
                  Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
                  ListTile(
                    onTap: () {
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
                      'Remove Wallpaper',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Reset to chat theme default background',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 11.5,
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
}
