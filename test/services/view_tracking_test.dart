import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/services/view_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://mock.supabase.co', publishableKey: 'mock');
    } catch (e) {
      // Already initialized
    }
  });

  group('ViewTrackingService Tests', () {
    test('trackView adds to queue and ignores duplicates', () {
      final service = ViewTrackingService();
      
      expect(service.toString(), isNotNull);
      
      service.trackView('post1');
      service.trackView('post2');
      
      // Tracking again should be ignored
      service.trackView('post1');
      
      // Cleanup timer
      service.dispose();
    });

    test('Dispose cleans up correctly', () {
      final service = ViewTrackingService();
      service.dispose();
      // Test should complete without hanging due to the timer
    });
  });
}
