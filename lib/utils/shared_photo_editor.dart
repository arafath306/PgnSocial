import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:dak/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedPhotoEditorScreen extends StatefulWidget {
  final File imageFile;

  const SharedPhotoEditorScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<SharedPhotoEditorScreen> createState() => _SharedPhotoEditorScreenState();
}

class _SharedPhotoEditorScreenState extends State<SharedPhotoEditorScreen> {
  // Store the edited result here. If null when onCloseEditor fires, the user cancelled.
  XFile? _editedResult;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final fgColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ProImageEditor.file(
      widget.imageFile,
      callbacks: ProImageEditorCallbacks(
        // STEP 1: Save the result only. Do NOT call Navigator.pop here.
        // The library is still busy (its loading dialog is open). If we pop here,
        // we will pop the wrong thing and crash.
        onImageEditingComplete: (Uint8List bytes) async {
          try {
            final dir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempFile = File('${dir.path}/edited_image_$timestamp.jpg');
            await tempFile.writeAsBytes(bytes);
            _editedResult = XFile(tempFile.path);
          } catch (e) {
            debugPrint('Error saving edited image: $e');
            _editedResult = null;
          }
        },

        // STEP 2: The library calls this AFTER it has fully cleaned up its dialogs.
        // This is the ONLY place we pop the editor screen. It's called for both
        // save (result != null) and cancel (result == null).
        onCloseEditor: (EditorMode mode) {
          if (context.mounted) {
            Navigator.of(context).pop(_editedResult);
          }
        },
      ),
      configs: ProImageEditorConfigs(
        designMode: ImageEditorDesignMode.material,
        imageGeneration: const ImageGenerationConfigs(
          processorConfigs: ProcessorConfigs(
            processorMode: ProcessorMode.minimum,
          ),
        ),
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
