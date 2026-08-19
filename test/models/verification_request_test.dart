import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/verification_request.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('VerificationRequest Model Tests', () {
    test('Default constructor sets expected default values', () {
      final req = VerificationRequest();
      
      expect(req.fullName, isEmpty);
      expect(req.idType, equals('nid'));
      expect(req.category, equals('general'));
      expect(req.selectedPlanId, equals('monthly'));
      expect(req.status, equals(VerificationStatus.incomplete));
      expect(req.hasBothIdImages, isFalse);
      expect(req.hasFaceImage, isFalse);
      expect(req.isBusiness, isFalse);
      expect(req.isGovernment, isFalse);
      expect(req.isPremiumPlan, isFalse);
    });

    test('hasBothIdImages is true only when both front and back are provided', () {
      final req = VerificationRequest();
      expect(req.hasBothIdImages, isFalse);
      
      req.nidFront = XFile('front.jpg');
      expect(req.hasBothIdImages, isFalse);
      
      req.nidBack = XFile('back.jpg');
      expect(req.hasBothIdImages, isTrue);
    });

    test('isBusiness returns true when category or plan contains business', () {
      final req1 = VerificationRequest(category: 'business');
      expect(req1.isBusiness, isTrue);
      
      final req2 = VerificationRequest(selectedPlanId: 'business_yearly');
      expect(req2.isBusiness, isTrue);
    });

    test('isGovernment returns true when category or plan contains government', () {
      final req1 = VerificationRequest(category: 'government');
      expect(req1.isGovernment, isTrue);
      
      final req2 = VerificationRequest(selectedPlanId: 'government_yearly');
      expect(req2.isGovernment, isTrue);
    });

    test('isPremiumPlan returns true when plan contains premium', () {
      final req = VerificationRequest(selectedPlanId: 'premium_monthly');
      expect(req.isPremiumPlan, isTrue);
    });
  });
}
