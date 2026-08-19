import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/state/monetization_controller.dart';

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

  group('MonetizationController Tests', () {
    test('Initial state is correct', () {
      final controller = MonetizationController();
      expect(controller.isEnabledGlobally, isFalse);
      expect(controller.isLoadingDashboard, isTrue);
      expect(controller.creatorSettings, isNull);
      expect(controller.activeSubscribers, 0);
      expect(controller.mySubscribedCreatorIds, isEmpty);
    });

    test('isSubscribedTo returns correctly', () {
      final controller = MonetizationController();
      expect(controller.isSubscribedTo('user123'), isFalse);
      
      controller.mySubscribedCreatorIds = ['user123'];
      expect(controller.isSubscribedTo('user123'), isTrue);
    });
  });
}
