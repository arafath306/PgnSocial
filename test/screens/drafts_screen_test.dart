import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/screens/drafts_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DraftsScreen Tests', () {
    testWidgets('Renders empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DraftsScreen()),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('No saved drafts'), findsOneWidget);
    });

    testWidgets('Renders drafts correctly if they exist', (WidgetTester tester) async {
      // Pre-populate SharedPreferences with a draft
      SharedPreferences.setMockInitialValues({
        'dak_user_drafts': [
          '{"id":"d1","content":"Hello Draft","audience":"Public","updatedAt":"2023-01-01T00:00:00.000Z"}'
        ]
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DraftsScreen()),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Hello Draft'), findsOneWidget);
    });
  });
}
