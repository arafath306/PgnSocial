import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to control native Android FLAG_SECURE screenshot & screen recording protection.
class ScreenshotProtectionService {
  static const MethodChannel _channel = MethodChannel('app.ngst.dak/screenshot_protection');

  /// Enable native screenshot & screen recording protection
  static Future<void> enableProtection() async {
    try {
      await _channel.invokeMethod('enableSecure');
      debugPrint('[ScreenshotProtection] Enabled FLAG_SECURE');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error enabling secure flag: $e');
    }
  }

  /// Disable native screenshot protection
  static Future<void> disableProtection() async {
    try {
      await _channel.invokeMethod('disableSecure');
      debugPrint('[ScreenshotProtection] Disabled FLAG_SECURE');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error disabling secure flag: $e');
    }
  }

  /// Automatically sync protection status with profile's premium status
  static Future<void> syncProtection(bool isPremium) async {
    if (isPremium) {
      await enableProtection();
    } else {
      await disableProtection();
    }
  }
}
