import 'package:flutter_test/flutter_test.dart';
import 'package:dak/services/log_service.dart';

void main() {
  group('LogService Tests', () {
    setUp(() {
      LogService.clear();
    });

    test('logging inserts a new entry at index 0', () {
      expect(LogService.logs, isEmpty);
      expect(LogService.logCountNotifier.value, equals(0));

      LogService.info('Test info message', tag: 'TEST');

      expect(LogService.logs.length, equals(1));
      expect(LogService.logCountNotifier.value, equals(1));

      final entry = LogService.logs[0];
      expect(entry.message, equals('Test info message'));
      expect(entry.type, equals('INFO'));
      expect(entry.tag, equals('TEST'));
    });

    test('multiple logs maintain maxLogs length limit', () {
      // maxLogs is 500
      for (int i = 0; i < 520; i++) {
        LogService.debug('Log message $i');
      }

      expect(LogService.logs.length, equals(500));
      expect(LogService.logCountNotifier.value, equals(500));

      // The first element should be the latest log (index 519)
      expect(LogService.logs.first.message, equals('Log message 519'));
    });

    test('clear resets logs list and count notifier', () {
      LogService.warning('Warning message');
      LogService.error('Error message');
      expect(LogService.logs.length, equals(2));

      LogService.clear();
      expect(LogService.logs, isEmpty);
      expect(LogService.logCountNotifier.value, equals(0));
    });

    test('different log types map to correct severity values', () {
      LogService.database('DB connection open');
      expect(LogService.logs[0].type, equals('DATABASE'));
      expect(LogService.logs[0].tag, equals('DATABASE'));

      LogService.auth('User token refreshed');
      expect(LogService.logs[0].type, equals('AUTH'));
      expect(LogService.logs[0].tag, equals('AUTH'));
    });
  });
}
