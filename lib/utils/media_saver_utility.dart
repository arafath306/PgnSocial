import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaSaverUtility {
  /// Downloads a photo or video from [url] and saves it directly to the device Gallery.
  static Future<void> saveToGallery(BuildContext context, String url, {bool isVideo = false}) async {
    try {
      // 1. Request Gallery Access Permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gallery permission required to save media.',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      // 2. Show Downloading Toast
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVideo ? 'Downloading video to Gallery...' : 'Downloading photo to Gallery...',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E824C),
          ),
        );
      }

      // 3. Fetch binary bytes
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final Uint8List bytes = response.bodyBytes;

      // 4. Save to Dedicated 'Pigeon Social' Album in Gallery
      if (isVideo) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await tempFile.writeAsBytes(bytes);
        await Gal.putVideo(tempFile.path, album: 'Pigeon Social');
        try { await tempFile.delete(); } catch (_) {}
      } else {
        await Gal.putImageBytes(bytes, album: 'Pigeon Social');
      }

      // 5. Success Feedback Toast
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isVideo ? 'Video saved to Gallery!' : 'Photo saved to Gallery!',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E824C),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Save to gallery error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save media: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
