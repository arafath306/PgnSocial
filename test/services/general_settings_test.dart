import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        publishableKey: 'mock',
      );
    } catch (e) {
      // Already initialized
    }
  });

  group('GeneralSettingsProvider Tests', () {
    test('Default privacy and feature flags state', () {
      final provider = GeneralSettingsProvider();
      expect(provider.isPrivateAccount, isFalse);
      expect(provider.allowMentionsFrom, 'everyone');
      expect(provider.filterAdultContent, isTrue);
      expect(provider.autoplayVideos, isTrue);
      expect(provider.isActiveStatusEnabled, isTrue);
      
      expect(provider.isVoicePostEnabled, isFalse);
      expect(provider.isTieredBadgesEnabled, isFalse);
      expect(provider.isAlgorithmicPriorityEnabled, isFalse);
      expect(provider.isAnonymousPostingEnabled, isFalse);
    });

    test('toggleTwoFactor updates state', () {
      final provider = GeneralSettingsProvider();
      expect(provider.isTwoFactorEnabled, isFalse);
      
      provider.toggleTwoFactor(true);
      expect(provider.isTwoFactorEnabled, isTrue);
    });

    test('Language and Theme settings updates locally', () async {
      final provider = GeneralSettingsProvider();
      
      await provider.changeLanguage(const Locale('bn'));
      expect(provider.appLocale, const Locale('bn'));
      
      await provider.toggleTheme(false);
      expect(provider.isDarkTheme, isFalse);
      expect(provider.themeMode, ThemeMode.light);
      
      await provider.toggleLowDataMode(true);
      expect(provider.lowDataMode, isTrue);
    });
  });
}
