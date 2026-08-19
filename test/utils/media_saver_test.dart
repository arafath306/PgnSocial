import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dak/utils/media_saver_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    const MethodChannel channel = MethodChannel('gal');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'hasAccess') return true;
      if (methodCall.method == 'requestAccess') return true;
      return null;
    });
  });

  group('MediaSaverUtility Tests', () {
    test('Class instantiation works', () {
      final utility = MediaSaverUtility();
      expect(utility, isNotNull);
    });
  });
}
