import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages device-tray (OS-level) notifications using flutter_local_notifications v22.
/// Supports:
///  - Per-type Android notification channels (messages, likes, follows, mentions)
///  - Grouped / inbox-style summary notifications per channel (Android 7+)
///  - Payload-based routing when user taps a notification
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Channel IDs & names ────────────────────────────────────────────────────
  static const String _channelMessages = 'pigeon_messages';
  static const String _channelLikes    = 'pigeon_likes';
  static const String _channelFollows  = 'pigeon_follows';
  static const String _channelMentions = 'pigeon_mentions';
  static const String _channelActivity = 'pigeon_activity';

  // ── Group keys (Android notification grouping) ─────────────────────────────
  static const String _groupMessages = 'group_messages';
  static const String _groupLikes    = 'group_likes';
  static const String _groupFollows  = 'group_follows';
  static const String _groupMentions = 'group_mentions';
  static const String _groupActivity = 'group_activity';

  // ── Summary notification IDs ───────────────────────────────────────────────
  static const int _summaryMessages = 1000;
  static const int _summaryLikes    = 1001;
  static const int _summaryFollows  = 1002;
  static const int _summaryMentions = 1003;
  static const int _summaryActivity = 1004;

  // ── In-memory inbox lines per group (for InboxStyle summary) ──────────────
  static final Map<String, List<String>> _inboxLines = {
    _groupMessages: [],
    _groupLikes   : [],
    _groupFollows : [],
    _groupMentions: [],
    _groupActivity: [],
  };

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
          debugPrint('Notification tapped: ${response.payload}');
          onNotificationTap?.call(response.payload);
        },
      );

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

  /// Creates all Android notification channels.
  static Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin plugin) async {
    final channels = [
      const AndroidNotificationChannel(
        _channelMessages,
        'Messages',
        description: 'Private message notifications',
        importance: Importance.max,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelLikes,
        'Likes & Reactions',
        description: 'Notifications when someone likes your post',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
      const AndroidNotificationChannel(
        _channelFollows,
        'Followers',
        description: 'Notifications when someone follows you',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelMentions,
        'Mentions',
        description: 'Notifications when someone mentions you',
        importance: Importance.high,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelActivity,
        'Activity',
        description: 'Comments, reposts, and other activity',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    ];
    for (final ch in channels) {
      await plugin.createNotificationChannel(ch);
    }
  }

  // ── Public helpers ─────────────────────────────────────────────────────────

  /// Show a **message** notification (high priority, own channel).
  static Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  }) async {
    final String displayMessage = "Sent you a message";
    final line = '$senderName: $displayMessage';
    _inboxLines[_groupMessages]!.add(line);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelMessages,
        'Messages',
        channelDescription: 'Private message notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'New message',
        groupKey: _groupMessages,
        setAsGroupSummary: false,
        onlyAlertOnce: true,
        styleInformation: BigTextStyleInformation(
          displayMessage,
          contentTitle: senderName,
          summaryText:
              '${_inboxLines[_groupMessages]!.length} new messages',
        ),
      ),
    );
    await _show(
        id: id, title: senderName, body: displayMessage, details: details, payload: payload);
    await _showSummary(
      summaryId: _summaryMessages,
      channelId: _channelMessages,
      channelName: 'Messages',
      groupKey: _groupMessages,
      title: 'New messages',
      lines: _inboxLines[_groupMessages]!,
      payload: 'messages',
    );
  }

  /// Show a **like** notification (grouped by post).
  static Future<void> showLikeNotification({
    required int id,
    required String actorName,
    required String postSnippet,
    String? payload,
  }) async {
    final line = '$actorName liked: $postSnippet';
    _inboxLines[_groupLikes]!.add(line);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelLikes,
        'Likes & Reactions',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        groupKey: _groupLikes,
        setAsGroupSummary: false,
        silent: true,
      ),
    );
    await _show(
        id: id,
        title: actorName,
        body: 'liked your post',
        details: details,
        payload: payload);
    await _showSummary(
      summaryId: _summaryLikes,
      channelId: _channelLikes,
      channelName: 'Likes & Reactions',
      groupKey: _groupLikes,
      title: '${_inboxLines[_groupLikes]!.length} new likes',
      lines: _inboxLines[_groupLikes]!,
      payload: 'likes',
    );
  }

  /// Show a **follow** notification.
  static Future<void> showFollowNotification({
    required int id,
    required String actorName,
    String? payload,
  }) async {
    final line = '$actorName started following you';
    _inboxLines[_groupFollows]!.add(line);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelFollows,
        'Followers',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        groupKey: _groupFollows,
        setAsGroupSummary: false,
      ),
    );
    await _show(
        id: id,
        title: actorName,
        body: 'started following you',
        details: details,
        payload: payload);
    await _showSummary(
      summaryId: _summaryFollows,
      channelId: _channelFollows,
      channelName: 'Followers',
      groupKey: _groupFollows,
      title: '${_inboxLines[_groupFollows]!.length} new followers',
      lines: _inboxLines[_groupFollows]!,
      payload: 'follows',
    );
  }

  /// Show a **mention** notification (high priority).
  static Future<void> showMentionNotification({
    required int id,
    required String actorName,
    required String snippet,
    String? payload,
  }) async {
    final line = '$actorName mentioned you: $snippet';
    _inboxLines[_groupMentions]!.add(line);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelMentions,
        'Mentions',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: _groupMentions,
        setAsGroupSummary: false,
      ),
    );
    await _show(
        id: id,
        title: 'You were mentioned',
        body: '$actorName: $snippet',
        details: details,
        payload: payload);
    await _showSummary(
      summaryId: _summaryMentions,
      channelId: _channelMentions,
      channelName: 'Mentions',
      groupKey: _groupMentions,
      title: '${_inboxLines[_groupMentions]!.length} new mentions',
      lines: _inboxLines[_groupMentions]!,
      payload: 'mentions',
    );
  }

  /// Show a generic **activity** notification (comment, repost, etc.).
  static Future<void> showActivityNotification({
    required int id,
    required String actorName,
    required String action,
    String? payload,
  }) async {
    final line = '$actorName $action';
    _inboxLines[_groupActivity]!.add(line);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelActivity,
        'Activity',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        groupKey: _groupActivity,
        setAsGroupSummary: false,
        silent: true,
      ),
    );
    await _show(
        id: id,
        title: actorName,
        body: action,
        details: details,
        payload: payload);
    await _showSummary(
      summaryId: _summaryActivity,
      channelId: _channelActivity,
      channelName: 'Activity',
      groupKey: _groupActivity,
      title: '${_inboxLines[_groupActivity]!.length} new activities',
      lines: _inboxLines[_groupActivity]!,
      payload: 'activity',
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
      ),
    );
    await _show(
        id: id, title: title, body: body, details: details, payload: payload);
  }

  /// Clear all stored inbox lines (e.g. when user opens the app / reads all).
  static void clearInbox() {
    for (final key in _inboxLines.keys) {
      _inboxLines[key]!.clear();
    }
    // Cancel summary notifications
    _plugin.cancel(id: _summaryMessages);
    _plugin.cancel(id: _summaryLikes);
    _plugin.cancel(id: _summaryFollows);
    _plugin.cancel(id: _summaryMentions);
    _plugin.cancel(id: _summaryActivity);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
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

  static Future<void> _showSummary({
    required int summaryId,
    required String channelId,
    required String channelName,
    required String groupKey,
    required String title,
    required List<String> lines,
    String? payload,
  }) async {
    if (lines.isEmpty) return;
    try {
      final inboxLines =
          lines.length > 5 ? lines.sublist(lines.length - 5) : lines;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.min,
          priority: Priority.low,
          groupKey: groupKey,
          setAsGroupSummary: true,
          silent: true,
          styleInformation: InboxStyleInformation(
            inboxLines,
            summaryText: '${lines.length} notifications',
            contentTitle: title,
          ),
        ),
      );
      await _plugin.show(
        id: summaryId,
        title: title,
        body: '${lines.length} notifications',
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing summary notification: $e');
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
