import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class MediaDownloadService {
  static Future<void> downloadMedia(BuildContext context, {List<String>? imageUrls, String? videoUrl}) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }
    } catch (e) {
      debugPrint("Gal permission check error (ignoring): $e");
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading media...')),
      );
    }

    try {
      final tempDir = await getTemporaryDirectory();


      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (var url in imageUrls) {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            String ext = '.jpg';
            if (url.toLowerCase().contains('.png')) ext = '.png';
            if (url.toLowerCase().contains('.webp')) ext = '.webp';
            if (url.toLowerCase().contains('.gif')) ext = '.gif';
            
            final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
            final file = File(tempPath);
            await file.writeAsBytes(response.bodyBytes);
            await Gal.putImage(tempPath, album: 'Pigeon');
          } else {
            throw Exception("Failed to download image: ${response.statusCode}");
          }
        }
      }

      if (videoUrl != null && videoUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          String ext = '.mp4';
          if (videoUrl.toLowerCase().contains('.mov')) ext = '.mov';
          
          final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
          final file = File(tempPath);
          await file.writeAsBytes(response.bodyBytes);
          await Gal.putVideo(tempPath, album: 'Pigeon');
        } else {
          throw Exception("Failed to download video: ${response.statusCode}");
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media saved to Pigeon folder in Gallery')),
        );
      }
    } catch (e) {
      debugPrint('Download media error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save media')),
        );
      }
    }
  }
}
