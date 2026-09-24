import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_navigation_handler.dart';

/// Manages device-tray (OS-level) notifications using flutter_local_notifications.
/// Configured for high-priority lock screen alerts (Twitter/Telegram style),
/// deduplication, and payload-based navigation.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Channel IDs & names ────────────────────────────────────────────────────
  static const String _channelMessages = 'pigeon_messages';
  static const String _channelLikes    = 'pigeon_likes';
  static const String _channelFollows  = 'pigeon_follows';
  static const String _channelMentions = 'pigeon_mentions';
  static const String _channelActivity = 'pigeon_activity';

  // ── Notification tap callback ──────────────────────────────────────────────
  static void Function(String? payload)? onNotificationTap;

  // ── Initialization ─────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: android);

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[LocalNotificationService] Notification tapped: ${response.payload}');
          if (onNotificationTap != null) {
            onNotificationTap!(response.payload);
          } else {
            NotificationNavigationHandler.handlePayload(response.payload);
          }
        },
      );

      // Default tap handler if not overridden
      onNotificationTap ??= (payload) => NotificationNavigationHandler.handlePayload(payload);

      // Check if cold-launched from a local notification
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.payload != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          NotificationNavigationHandler.handlePayload(
              launchDetails!.notificationResponse!.payload);
        });
      }

      // Request POST_NOTIFICATIONS permission on Android 13+
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await _createChannels(androidPlugin);
      }
    } catch (e) {
      debugPrint('LocalNotificationService init error: $e');
    }
  }

  /// Creates all Android notification channels with Max/High importance and Lock Screen support.
  static Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin plugin) async {
    final channels = [
      const AndroidNotificationChannel(
        _channelMessages,
        'Messages',
        description: 'Direct message notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        _channelMentions,
        'Mentions',
        description: 'Notifications when someone mentions you',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        _channelActivity,
        'Activity',
        description: 'Comments, reposts, and post activity',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        _channelFollows,
        'Followers',
        description: 'Notifications when someone follows you',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        _channelLikes,
        'Likes & Reactions',
        description: 'Notifications when someone likes your post',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    ];
    for (final ch in channels) {
      await plugin.createNotificationChannel(ch);
    }
  }

  // ── Public helpers ─────────────────────────────────────────────────────────

  /// Show a **message** notification (high priority, lockscreen-visible, single alert).
  static Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  }) async {
    final String displayBody = message.isNotEmpty ? message : "Sent you a message";

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelMessages,
        'Messages',
        channelDescription: 'Direct message notifications',
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.message,
        ticker: 'New message',
        showWhen: true,
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(
          displayBody,
          contentTitle: senderName,
        ),
      ),
    );

    await _show(
      id: id,
      title: senderName,
      body: displayBody,
      details: details,
      payload: payload,
    );
  }

  /// Show a **like** notification.
  static Future<void> showLikeNotification({
    required int id,
    required String actorName,
    required String postSnippet,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelLikes,
        'Likes & Reactions',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.social,
        silent: true,
        showWhen: true,
      ),
    );

    await _show(
      id: id,
      title: actorName,
      body: 'liked your post: $postSnippet',
      details: details,
      payload: payload,
    );
  }

  /// Show a **follow** notification.
  static Future<void> showFollowNotification({
    required int id,
    required String actorName,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelFollows,
        'Followers',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.social,
        showWhen: true,
      ),
    );

    await _show(
      id: id,
      title: actorName,
      body: 'started following you',
      details: details,
      payload: payload,
    );
  }

  /// Show a **mention** notification (high priority).
  static Future<void> showMentionNotification({
    required int id,
    required String actorName,
    required String snippet,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelMentions,
        'Mentions',
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.social,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          snippet,
          contentTitle: '$actorName mentioned you',
        ),
      ),
    );

    await _show(
      id: id,
      title: '$actorName mentioned you',
      body: snippet,
      details: details,
      payload: payload,
    );
  }

  /// Show a generic **activity** notification (comment, repost, etc.).
  static Future<void> showActivityNotification({
    required int id,
    required String actorName,
    required String action,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelActivity,
        'Activity',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.social,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          action,
          contentTitle: actorName,
        ),
      ),
    );

    await _show(
      id: id,
      title: actorName,
      body: action,
      details: details,
      payload: payload,
    );
  }

  // ── Legacy helper (kept for backwards compatibility) ───────────────────────
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelActivity,
        'Activity',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        showWhen: true,
      ),
    );
    await _show(
      id: id,
      title: title,
      body: body,
      details: details,
      payload: payload,
    );
  }

  /// Clear all stored notifications or cancel active ones.
  static void clearInbox() {
    _recentNotificationCache.clear();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static final Map<String, DateTime> _recentNotificationCache = {};

  /// Checks if a notification with identical title and body was rendered within the last 5 seconds.
  /// Prevents duplicate alerts when FCM and Realtime WebSocket deliver simultaneously.
  static bool shouldSuppressDuplicate(String title, String body) {
    final now = DateTime.now();
    _recentNotificationCache.removeWhere(
      (_, timestamp) => now.difference(timestamp).inSeconds > 5,
    );

    final key = '${title.trim()}|||${body.trim()}';
    if (_recentNotificationCache.containsKey(key)) {
      debugPrint('[LocalNotificationService] Suppressed duplicate notification: "$title"');
      return true;
    }

    _recentNotificationCache[key] = now;
    return false;
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
    if (shouldSuppressDuplicate(title, body)) {
      return;
    }

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Cancels a specific notification by ID (e.g. when entering that user's chat)
  static Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}

