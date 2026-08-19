import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/services/presence_service.dart';

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

  group('PresenceService Tests', () {
    test('Initialization works', () {
      final service = PresenceService();
      
      // Test initialization
      service.initialize('user123');
      
      // Test page updates
      service.updatePage('home');
      service.updatePage('profile');
      
      // Shouldn't crash
      expect(service, isNotNull);
      
      service.dispose();
    });
    
    test('Singleton pattern works', () {
      final service1 = PresenceService();
      final service2 = PresenceService();
      
      expect(identical(service1, service2), isTrue);
    });
  });
}
