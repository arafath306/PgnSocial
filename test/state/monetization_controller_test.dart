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

    test('Accounting getters compute net, payouts, and availableBalance accurately', () {
      final controller = MonetizationController();
      controller.totalGrossRevenue = 1000.0; // 1000 gross
      // 90% net = 900.0
      expect(controller.totalLifetimeNet, equals(900.0));
      expect(controller.totalLifetimeFee, equals(100.0));

      // With no payout requests, availableBalance equals totalLifetimeNet
      expect(controller.availableBalance, equals(900.0));
      expect(controller.totalRequestedOrPaid, equals(0.0));

      // Add payout requests: 1 paid (300), 1 pending (100), 1 rejected (200)
      controller.payoutRequests = [
        {'amount': 300.0, 'status': 'paid'},
        {'amount': 100.0, 'status': 'pending'},
        {'amount': 200.0, 'status': 'rejected'},
      ];

      // Rejected should not count against balance
      expect(controller.paidPayoutAmount, equals(300.0));
      expect(controller.pendingPayoutAmount, equals(100.0));
      expect(controller.totalRequestedOrPaid, equals(400.0));
      // Available = 900 - 400 = 500
      expect(controller.availableBalance, equals(500.0));
    });

    test('AvailableBalance never goes below zero', () {
      final controller = MonetizationController();
      controller.totalGrossRevenue = 100.0; // net 90.0
      controller.payoutRequests = [
        {'amount': 200.0, 'status': 'paid'},
      ];
      expect(controller.availableBalance, equals(0.0));
    });
  });
}
