import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:dak/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedPhotoEditorScreen extends StatelessWidget {
  final File imageFile;

  const SharedPhotoEditorScreen({
    super.key,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final fgColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ProImageEditor.file(
      imageFile,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          try {
            final dir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempFile = File('${dir.path}/edited_image_$timestamp.jpg');
            await tempFile.writeAsBytes(bytes);

            if (context.mounted) {
              Navigator.pop(context, XFile(tempFile.path));
            }
          } catch (e) {
            debugPrint('Error saving edited image: $e');
            if (context.mounted) {
              Navigator.pop(context, null);
            }
          }
        },
        onCloseEditor: (EditorMode mode) {
          Navigator.pop(context, null);
        },
      ),
      configs: ProImageEditorConfigs(
        designMode: ImageEditorDesignMode.material,
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: bgColor,
          colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
            primary: context.primaryAccent,
            secondary: fgColor,
            surface: bgColor,
            onSurface: fgColor,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: fgColor),
            titleTextStyle: GoogleFonts.inter(
              color: fgColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: bgColor,
            selectedItemColor: fgColor,
            unselectedItemColor: fgColor.withValues(alpha: 0.5),
          ),
          iconTheme: IconThemeData(color: fgColor),
          textTheme: GoogleFonts.interTextTheme(
            isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
          ),
        ),
      ),
    );
  }
}
