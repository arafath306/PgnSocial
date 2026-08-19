import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/music_track.dart';

void main() {
  group('MusicTrack Model Tests', () {
    test('fromMap parses map properties correctly', () {
      final map = {
        'trackId': 'track_123',
        'trackName': 'Song Title',
        'artistName': 'Famous Artist',
        'previewUrl': 'http://preview.mp3',
        'artworkUrl': 'http://artwork.png',
      };

      final track = MusicTrack.fromMap(map);

      expect(track.trackId, equals('track_123'));
      expect(track.trackName, equals('Song Title'));
      expect(track.artistName, equals('Famous Artist'));
      expect(track.previewUrl, equals('http://preview.mp3'));
      expect(track.artworkUrl, equals('http://artwork.png'));
    });

    test('fromMap handles missing/null properties with default empty strings', () {
      final map = <String, dynamic>{};

      final track = MusicTrack.fromMap(map);

      expect(track.trackId, isEmpty);
      expect(track.trackName, isEmpty);
      expect(track.artistName, isEmpty);
      expect(track.previewUrl, isEmpty);
      expect(track.artworkUrl, isEmpty);
    });

    test('toMap serializes properties correctly (except artistName as defined)', () {
      final track = MusicTrack(
        trackId: 'track_456',
        trackName: 'Track B',
        artistName: 'Artist B',
        previewUrl: 'http://preview2.mp3',
        artworkUrl: 'http://artwork2.png',
      );

      final map = track.toMap();

      expect(map['trackId'], equals('track_456'));
      expect(map['trackName'], equals('Track B'));
      expect(map.containsKey('artistName'), isFalse); // artistName is not in toMap()
      expect(map['previewUrl'], equals('http://preview2.mp3'));
      expect(map['artworkUrl'], equals('http://artwork2.png'));
    });

    test('toJson and fromJson round-trip (excluding artistName)', () {
      final track = MusicTrack(
        trackId: 'track_789',
        trackName: 'Track C',
        artistName: 'Artist C',
        previewUrl: 'http://preview3.mp3',
        artworkUrl: 'http://artwork3.png',
      );

      final jsonStr = track.toJson();
      final decoded = MusicTrack.fromJson(jsonStr);

      expect(decoded.trackId, equals('track_789'));
      expect(decoded.trackName, equals('Track C'));
      expect(decoded.artistName, isEmpty); // artistName is lost since it is not in toMap/toJson
      expect(decoded.previewUrl, equals('http://preview3.mp3'));
      expect(decoded.artworkUrl, equals('http://artwork3.png'));
    });
  });
}
