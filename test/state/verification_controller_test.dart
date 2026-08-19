import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/state/verification_controller.dart';
import 'package:dak/models/verification_request.dart';

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

  group('VerificationController Tests', () {
    test('Initial state is correct', () {
      final controller = VerificationController();
      expect(controller.isSubmitting, isFalse);
      expect(controller.request.status, VerificationStatus.incomplete);
      expect(controller.request.fullName, '');
    });
  });
}
