import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/widgets/verification_badge.dart';

void main() {
  group('VerificationBadge Tests', () {
    testWidgets('Does not render if not verified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationBadge(isVerified: false),
          ),
        ),
      );
      
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('Renders blue badge by default if verified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationBadge(isVerified: true),
          ),
        ),
      );
      
      final iconFinder = find.byIcon(Icons.verified_rounded);
      expect(iconFinder, findsOneWidget);
      
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, const Color(0xFF0095F6));
    });

    testWidgets('Renders gold badge for business/gold types', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationBadge(isVerified: true, badgeType: 'business'),
          ),
        ),
      );
      
      final iconFinder = find.byIcon(Icons.verified_rounded);
      expect(iconFinder, findsOneWidget);
      
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, const Color(0xFFD97706));
    });
    
    testWidgets('Renders gray badge for government types', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationBadge(isVerified: true, badgeType: 'government'),
          ),
        ),
      );
      
      final iconFinder = find.byIcon(Icons.verified_rounded);
      expect(iconFinder, findsOneWidget);
      
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, const Color(0xFF64748B));
    });
  });
}
