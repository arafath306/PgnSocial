import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/state/music_playback_controller.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel channel = MethodChannel('xyz.luan/audioplayers');
    const MethodChannel globalChannel = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalChannel, (MethodCall methodCall) async {
      return 1;
    });
  });

  group('MusicPlaybackController Tests', () {
    test('Initialization does not crash', () {
      final controller = MusicPlaybackController();
      expect(controller.isPlaying, isFalse);
      expect(controller.autoplayMusic, isTrue);
      expect(controller.currentTrackId, isNull);
    });
  });
}
