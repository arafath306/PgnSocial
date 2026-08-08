import 'package:intl/intl.dart';

/// Helper utilities for WhatsApp-style chat date headers & timestamps.
class ChatDateFormatter {
  /// Format a DateTime into WhatsApp-style date header badges:
  /// - Today
  /// - Yesterday
  /// - Weekday (e.g., Monday, Friday) for messages within last 7 days
  /// - Day & Month (e.g., 12 Oct) for messages within the current year
  /// - Full Date with Year (e.g., 14 Nov 2024) for older years
  static String formatWhatsAppDateBadge(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diffDays = today.difference(msgDate).inDays;

    if (isSameDay(msgDate, today)) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (isSameDay(msgDate, yesterday)) {
      return 'Yesterday';
    }

    if (diffDays > 1 && diffDays < 7) {
      return DateFormat('EEEE').format(dateTime); // e.g. Monday, Friday
    }

    if (dateTime.year == now.year) {
      return DateFormat('d MMM').format(dateTime); // e.g. 12 Oct
    }

    return DateFormat('d MMM yyyy').format(dateTime); // e.g. 14 Nov 2024
  }

  /// Checks if two DateTimes represent the exact same calendar day
  static bool isSameDay(DateTime? dt1, DateTime? dt2) {
    if (dt1 == null || dt2 == null) return false;
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }

  /// Parses message timestamp object or string to DateTime (converting to local time)
  static DateTime parseMessageDateTime(Map<String, dynamic> msg) {
    final createdAt = msg['created_at'];
    if (createdAt != null) {
      try {
        if (createdAt is DateTime) return createdAt.toLocal();
        return DateTime.parse(createdAt.toString()).toLocal();
      } catch (_) {}
    }
    return DateTime.now();
  }
}
