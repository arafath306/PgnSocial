import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/screens/communities/create_community_screen.dart';
import 'package:dak/services/community_service.dart';

class MockCommunityService extends ChangeNotifier implements CommunityService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isHandleAvailable(String handle) async {
    return true;
  }
}

void main() {
  group('CreateCommunityScreen Tests', () {
    late MockCommunityService mockService;

    setUp(() {
      mockService = MockCommunityService();
    });

    Widget buildApp() {
      return ChangeNotifierProvider<CommunityService>.value(
        value: mockService,
        child: const MaterialApp(
          home: CreateCommunityScreen(),
        ),
      );
    }

    testWidgets('Renders screen and initial step title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('What is your community about?'), findsOneWidget);
    });

    testWidgets('Can select a topic and tap Next', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Tap first topic card
      await tester.tap(find.text('AI & Future Tech'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be in step 2: choose privacy
      expect(find.text('Community Type'), findsOneWidget);
    });
  });
}
