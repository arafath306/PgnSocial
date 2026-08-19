import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/utils/app_theme.dart';
void main() {
  group('AppTheme Tests', () {
    test('brand color constants are defined correctly', () {
      expect(AppTheme.primary, equals(const Color(0xFF1E824C)));
      expect(AppTheme.secondary, equals(const Color(0xFFFF6B4A)));
      expect(AppTheme.background, equals(const Color(0xFF070B16)));
      expect(AppTheme.surface, equals(const Color(0xFF0D1323)));
      expect(AppTheme.card, equals(const Color(0xFF111827)));
    });

    test('lightTheme has correct brightness and primary color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.primaryColor, equals(AppTheme.primary));
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.lightBackground));
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme has correct brightness and primary color', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.primaryColor, equals(AppTheme.primary));
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.background));
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('AppThemeExtension context getters return correct colors for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              expect(context.isDarkMode, isFalse);
              expect(context.scaffoldBg, equals(const Color(0xFFF8FAFC)));
              expect(context.cardBg, equals(const Color(0xFFFFFFFF)));
              expect(context.border, equals(const Color(0xFFE2E8F0)));
              expect(context.textPrimary, equals(const Color(0xFF0F172A)));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('AppThemeExtension context getters return correct colors for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              expect(context.isDarkMode, isTrue);
              expect(context.scaffoldBg, equals(const Color(0xFF070B16)));
              expect(context.cardBg, equals(const Color(0xFF111827)));
              expect(context.border, equals(const Color(0xFF1E293B)));
              expect(context.textPrimary, equals(Colors.white));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
