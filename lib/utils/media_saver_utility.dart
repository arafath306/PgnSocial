import 'package:flutter/material.dart';
import '../services/media_download_service.dart';

class MediaSaverUtility {
  /// Downloads a photo or video from [url] and saves it directly to the device Gallery.
  static Future<void> saveToGallery(BuildContext context, String url, {bool isVideo = false}) async {
    if (isVideo) {
      await MediaDownloadService.downloadMedia(context, videoUrl: url);
    } else {
      await MediaDownloadService.downloadMedia(context, imageUrls: [url]);
    }
  }
}
