import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/services/notification_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default notification settings load correctly', () async {
      final provider = NotificationSettingsProvider();
      
      final likesSetting = provider.getSetting('likes');
      expect(likesSetting, isNotNull);
      expect(likesSetting!.inApp, isTrue);
      expect(likesSetting.push, isTrue);
      expect(likesSetting.from, 'everyone');
    });

    test('updateSetting works and persists to SharedPreferences', () async {
      final provider = NotificationSettingsProvider();
      
      await provider.updateSetting(id: 'likes', push: false, from: 'off');
      
      final likesSetting = provider.getSetting('likes');
      expect(likesSetting!.push, isFalse);
      expect(likesSetting.from, 'off');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_likes_push'), isFalse);
      expect(prefs.getString('notif_likes_from'), 'off');
    });
  });
}
