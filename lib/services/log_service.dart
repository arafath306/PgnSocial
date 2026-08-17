import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final String type; // 'INFO', 'DEBUG', 'WARNING', 'ERROR', 'DATABASE', 'AUTH'
  final String tag;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
    required this.tag,
  });
}

class LogService {
  static final List<LogEntry> logs = [];
  static const int maxLogs = 500;
  static final ValueNotifier<int> logCountNotifier = ValueNotifier(0);

  static void info(String message, {String tag = 'APP'}) => log(message, type: 'INFO', tag: tag);
  static void debug(String message, {String tag = 'APP'}) => log(message, type: 'DEBUG', tag: tag);
  static void warning(String message, {String tag = 'APP'}) => log(message, type: 'WARNING', tag: tag);
  static void error(String message, {String tag = 'APP'}) => log(message, type: 'ERROR', tag: tag);
  static void database(String message, {String tag = 'DATABASE'}) => log(message, type: 'DATABASE', tag: tag);
  static void auth(String message, {String tag = 'AUTH'}) => log(message, type: 'AUTH', tag: tag);

  static void log(String message, {String type = 'INFO', String tag = 'APP'}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      tag: tag,
    );
    logs.insert(0, entry);
    if (logs.length > maxLogs) {
      logs.removeLast();
    }
    // Notify listeners on the main thread
    logCountNotifier.value = logs.length;
    
    // Fallback console log
    debugPrint('[$type][$tag] $message');
  }

  static void clear() {
    logs.clear();
    logCountNotifier.value = 0;
  }
}
