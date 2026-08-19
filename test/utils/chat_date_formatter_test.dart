import 'package:flutter_test/flutter_test.dart';
import 'package:dak/utils/chat_date_formatter.dart';

void main() {
  group('ChatDateFormatter Tests', () {
    test('formatWhatsAppDateBadge returns Today for same calendar day', () {
      final now = DateTime.now();
      expect(ChatDateFormatter.formatWhatsAppDateBadge(now), equals('Today'));
    });

    test('formatWhatsAppDateBadge returns Yesterday for yesterday calendar day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(ChatDateFormatter.formatWhatsAppDateBadge(yesterday), equals('Yesterday'));
    });

    test('formatWhatsAppDateBadge returns EEEE (e.g. Weekday) for messages 2-6 days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      // Just check that it is not Today/Yesterday/date format (usually it contains letters of weekday)
      final badge = ChatDateFormatter.formatWhatsAppDateBadge(threeDaysAgo);
      expect(badge, isNot(equals('Today')));
      expect(badge, isNot(equals('Yesterday')));
      expect(badge.length, greaterThan(2));
    });

    test('formatWhatsAppDateBadge returns "d MMM" format for older dates in current year', () {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month - 1 >= 1 ? now.month - 1 : 12, 1);
      final badge = ChatDateFormatter.formatWhatsAppDateBadge(date);
      // It should not contain the year
      expect(badge, isNot(contains(now.year.toString())));
    });

    test('formatWhatsAppDateBadge returns "d MMM yyyy" format for older years', () {
      final now = DateTime.now();
      final date = DateTime(now.year - 2, 5, 20);
      final badge = ChatDateFormatter.formatWhatsAppDateBadge(date);
      expect(badge, contains((now.year - 2).toString()));
    });

    test('isSameDay matches correct calendars', () {
      final dt1 = DateTime(2025, 8, 12, 10, 30);
      final dt2 = DateTime(2025, 8, 12, 23, 59);
      final dt3 = DateTime(2025, 8, 13, 0, 1);

      expect(ChatDateFormatter.isSameDay(dt1, dt2), isTrue);
      expect(ChatDateFormatter.isSameDay(dt1, dt3), isFalse);
      expect(ChatDateFormatter.isSameDay(null, dt1), isFalse);
    });

    test('parseMessageDateTime parses created_at or fallback fields successfully', () {
      final now = DateTime.now();
      // From DateTime object
      final msg1 = {'created_at': now};
      expect(ChatDateFormatter.parseMessageDateTime(msg1).day, equals(now.day));

      // From ISO string
      final msg2 = {'created_at': '2025-08-12T10:30:00Z'};
      expect(ChatDateFormatter.parseMessageDateTime(msg2).year, equals(2025));

      // From WhatsApp style simple time string fallback
      final msg3 = {'time': '10:30 AM'};
      final parsed = ChatDateFormatter.parseMessageDateTime(msg3);
      expect(parsed.hour, equals(10));
      expect(parsed.minute, equals(30));
    });
  });
}
