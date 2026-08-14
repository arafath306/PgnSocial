import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_photo_editor.dart';

class MediaPreviewScreen extends StatefulWidget {
  final List<XFile> initialImages;

  const MediaPreviewScreen({
    super.key,
    required this.initialImages,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  late List<XFile> _images;
  int _currentIndex = 0;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _cropImage(int index) async {
    final originalFile = _images[index];
    
    final editedFile = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (context) => SharedPhotoEditorScreen(
          imageFile: File(originalFile.path),
        ),
      ),
    );

    if (editedFile != null) {
      if (mounted) {
        setState(() {
          _images[index] = editedFile;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) {
        Navigator.pop(context);
      } else if (_currentIndex >= _images.length) {
        _currentIndex = _images.length - 1;
      }
    });
  }

  Future<void> _processAndSend() async {
    setState(() => _isCompressing = true);
    try {
      final List<Uint8List> processedBytes = [];

      for (final image in _images) {
        // Compress image for much faster upload
        final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 1080,
          minHeight: 1080,
          quality: 70,
          format: CompressFormat.jpeg,
        );

        if (compressed != null) {
          processedBytes.add(compressed);
        } else {
          // Fallback if compression fails
          processedBytes.add(await image.readAsBytes());
        }
      }

      if (mounted) {
        Navigator.pop(context, processedBytes);
      }
    } catch (e) {
      debugPrint("Compression error: \$e");
      if (mounted) {
        // Fallback to uncompressed if library fails
        final List<Uint8List> rawBytes = [];
        for (final img in _images) {
          rawBytes.add(await img.readAsBytes());
        }
        if (mounted) Navigator.pop(context, rawBytes);
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) return const SizedBox.shrink();

    final currentImage = _images[_currentIndex];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview (${_currentIndex + 1}/${_images.length})',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.primaryAccent),
            onPressed: () => _cropImage(_currentIndex),
            tooltip: 'Edit Image',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _removeImage(_currentIndex),
            tooltip: 'Remove',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main image preview
            Expanded(
              child: Center(
                child: Image.file(
                  File(currentImage.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Thumbnail selector if multiple images
            if (_images.length > 1)
              Container(
                height: 80,
                color: context.cardBg,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? context.primaryAccent : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_images[index].path),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Send bar
            Container(
              padding: const EdgeInsets.all(16),
              color: context.cardBg,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Ready to send ${_images.length} photo${_images.length > 1 ? 's' : ''}",
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _isCompressing
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : InkWell(
                          onTap: _processAndSend,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
