import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/draft_post.dart';
import 'package:dak/models/music_track.dart';

void main() {
  group('DraftPost Model Tests', () {
    test('fromMap and toMap round-trip parses successfully', () {
      final now = DateTime.now();
      final draft = DraftPost(
        id: 'draft_123',
        content: 'This is a draft thread content',
        imagePaths: ['/path/to/img1.png', '/path/to/img2.png'],
        videoUrl: 'http://video.mp4',
        audience: 'Friends',
        location: 'Dhaka, Bangladesh',
        pollOptions: ['Yes', 'No'],
        pollDurationHours: 24,
        updatedAt: now,
        musicTrack: MusicTrack(
          trackId: 'track1',
          trackName: 'Music Title',
          artistName: 'Artist A',
          previewUrl: 'http://preview.mp3',
          artworkUrl: 'http://artwork.png',
        ),
      );

      final map = draft.toMap();
      final decoded = DraftPost.fromMap(map);

      expect(decoded.id, equals('draft_123'));
      expect(decoded.content, equals('This is a draft thread content'));
      expect(decoded.imagePaths, equals(['/path/to/img1.png', '/path/to/img2.png']));
      expect(decoded.videoUrl, equals('http://video.mp4'));
      expect(decoded.audience, equals('Friends'));
      expect(decoded.location, equals('Dhaka, Bangladesh'));
      expect(decoded.pollOptions, equals(['Yes', 'No']));
      expect(decoded.pollDurationHours, equals(24));
      expect(decoded.updatedAt.toIso8601String(), equals(now.toIso8601String()));
      expect(decoded.musicTrack!.trackId, equals('track1'));
      expect(decoded.musicTrack!.trackName, equals('Music Title'));
      expect(decoded.musicTrack!.previewUrl, equals('http://preview.mp3'));
      expect(decoded.musicTrack!.artworkUrl, equals('http://artwork.png'));
    });

    test('fromMap handles null and missing values with defaults', () {
      final now = DateTime.now();
      final map = {
        'id': 'draft_456',
        'updatedAt': now.toIso8601String(),
      };

      final decoded = DraftPost.fromMap(map);

      expect(decoded.id, equals('draft_456'));
      expect(decoded.content, isEmpty);
      expect(decoded.imagePaths, isEmpty);
      expect(decoded.videoUrl, isNull);
      expect(decoded.audience, equals('Public'));
      expect(decoded.location, isNull);
      expect(decoded.pollOptions, isNull);
      expect(decoded.pollDurationHours, isNull);
      expect(decoded.musicTrack, isNull);
      expect(decoded.updatedAt.toIso8601String(), equals(now.toIso8601String()));
    });

    test('toJson and fromJson parses correctly', () {
      final now = DateTime.utc(2025, 8, 12, 10, 30);
      final draft = DraftPost(
        id: 'draft_789',
        content: 'Json draft',
        audience: 'Public',
        updatedAt: now,
      );

      final jsonStr = draft.toJson();
      final decoded = DraftPost.fromJson(jsonStr);

      expect(decoded.id, equals('draft_789'));
      expect(decoded.content, equals('Json draft'));
      expect(decoded.updatedAt.toIso8601String(), equals(now.toIso8601String()));
    });
  });
}
