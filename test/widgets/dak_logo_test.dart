import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/widgets/dak_logo.dart';

void main() {
  group('DakLogo Tests', () {
    testWidgets('Renders with correct asset image', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DakLogo(size: 50),
          ),
        ),
      );
      
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, 'assets/dak_icon.png');
      expect(image.width, 50);
    });

    testWidgets('Uses custom color if provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DakLogo(color: Colors.red),
          ),
        ),
      );
      
      final imageFinder = find.byType(Image);
      final image = tester.widget<Image>(imageFinder);
      expect(image.color, Colors.red);
    });
  });
}
