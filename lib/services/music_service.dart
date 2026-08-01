import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';

class MusicService {
  static Future<List<MusicTrack>> searchMusic(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=30');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((item) {
          String artworkUrl = item['artworkUrl100']?.toString() ?? '';
          // Scale it up to 400x400 for a higher resolution premium appearance
          if (artworkUrl.contains('100x100bb.jpg')) {
            artworkUrl = artworkUrl.replaceAll('100x100bb.jpg', '400x400bb.jpg');
          }
          return MusicTrack(
            trackId: item['trackId']?.toString() ?? item['artistId']?.toString() ?? '',
            trackName: item['trackName']?.toString() ?? 'Unknown Track',
            artistName: item['artistName']?.toString() ?? 'Unknown Artist',
            previewUrl: item['previewUrl']?.toString() ?? '',
            artworkUrl: artworkUrl,
          );
        }).where((track) => track.previewUrl.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('iTunes search music error: $e');
    }
    return [];
  }
}
