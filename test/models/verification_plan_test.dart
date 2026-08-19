import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/verification_plan_pricing.dart';

void main() {
  group('VerificationPlanPricing Model Tests', () {
    test('VerificationPlanPricing constructor maps properties correctly', () {
      const plan = VerificationPlanPricing(
        id: 'test_plan',
        category: 'general',
        duration: 'monthly',
        tier: 'premium',
        name: 'Test Plan',
        basePrice: 100.0,
        discountPrice: 90.0,
      );

      expect(plan.id, equals('test_plan'));
      expect(plan.category, equals('general'));
      expect(plan.duration, equals('monthly'));
      expect(plan.tier, equals('premium'));
      expect(plan.name, equals('Test Plan'));
      expect(plan.basePrice, equals(100.0));
      expect(plan.discountPrice, equals(90.0));
    });

    test('getPlan returns accurate static plan when exact match exists', () {
      final plan = VerificationPlanPricing.getPlan('general_monthly_premium');
      expect(plan.id, equals('general_monthly_premium'));
      expect(plan.category, equals('general'));
      expect(plan.duration, equals('monthly'));
      expect(plan.tier, equals('premium'));
      expect(plan.basePrice, equals(380.0));
      expect(plan.discountPrice, equals(350.0));
    });

    test('getPlan normalizes media category to government alias correctly', () {
      final plan = VerificationPlanPricing.getPlan('media_weekly_premium');
      expect(plan.id, equals('government_weekly_premium')); // normalized!
      expect(plan.category, equals('government'));
    });

    test('getPlan dynamically parses custom formats and falls back properly', () {
      // Dynamic fallback via splits
      final plan1 = VerificationPlanPricing.getPlan('media_lifetime_premium');
      expect(plan1.id, equals('government_lifetime_premium'));

      // Complete invalid ID fallback
      final plan2 = VerificationPlanPricing.getPlan('invalid_plan_id_completely');
      expect(plan2.id, equals('general_monthly_basic')); // default fallback
    });
  });
}
