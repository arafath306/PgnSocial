import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/screens/full_screen_media_viewer.dart';


void main() {
  group('FullScreenMediaViewer Tests', () {
    testWidgets('Renders single image correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullScreenMediaViewer(
              initialIndex: 0,
              imageUrls: ['https://example.com/image1.jpg'],
            ),
          ),
        ),
      );
      
      // PageView should be present
      expect(find.byType(PageView), findsOneWidget);
      
      // The hero tag is generated in the widget, usually based on url and index
      expect(find.byType(InteractiveViewer), findsWidgets);
    });

    testWidgets('Shows correct image count in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullScreenMediaViewer(
              initialIndex: 1,
              imageUrls: ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
            ),
          ),
        ),
      );
      
      // Expect the title to show "2 of 2" since index is 1 (0-based)
      expect(find.text('2 / 2'), findsOneWidget);
    });
  });
}
