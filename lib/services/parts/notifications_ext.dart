part of '../database_service.dart';

extension NotificationsExtension on DatabaseService {
  // --- Notifications ---

  Future<void> fetchNotifications() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select('*, actor:profiles!actor_id(*)')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _notifications = data.map((json) {
        return AppNotification.fromJson(json as Map<String, dynamic>);
      }).toList();
      updateState();
    } catch (e) {
      debugPrint("Fetch notifications error: $e");
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      // Update local state immediately
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        if (!old.read) {
          _unreadNotificationsCount = (_unreadNotificationsCount - 1).clamp(0, 999999);
        }
        _notifications[idx] = AppNotification(
          id: old.id,
          userId: old.userId,
          actor: old.actor,
          type: old.type,
          threadId: old.threadId,
          content: old.content,
          createdAt: old.createdAt,
          read: true,
          createdAtDateTime: old.createdAtDateTime,
        );
        updateState();
      }
    } catch (e) {
      debugPrint("Mark notification read error: $e");
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUid)
          .eq('is_read', false);
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        actor: n.actor,
        type: n.type,
        threadId: n.threadId,
        content: n.content,
        createdAt: n.createdAt,
        read: true,
        createdAtDateTime: n.createdAtDateTime,
      )).toList();
      _unreadNotificationsCount = 0;
      updateState();
    } catch (e) {
      debugPrint("Mark all notifications read error: $e");
    }
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Batch creates mention notifications for all @usernames found in [content].
  /// Resolves usernames in a single query, filters out self-mentions,
  /// and bulk-inserts notification records in one database request.
  Future<void> sendMentionNotificationsBatch({
    required String content,
    required String threadId,
    bool isComment = false,
  }) async {
    if (_currentUid.isEmpty || content.trim().isEmpty) return;
    try {
      final List<String> mentions = HashtagMentionParser.extractMentions(content);
      if (mentions.isEmpty) return;

      // 1. Fetch matching user IDs in one batch query
      final response = await _supabase
          .from('profiles')
          .select('id, username')
          .inFilter('username', mentions);

      final List<dynamic> profilesData = response as List<dynamic>;
      if (profilesData.isEmpty) return;

      // 2. Filter out self-mentions and duplicate user IDs
      final targetUserIds = <String>{};
      for (final p in profilesData) {
        final uid = p['id'] as String?;
        if (uid != null && uid.isNotEmpty && uid != _currentUid) {
          targetUserIds.add(uid);
        }
      }

      if (targetUserIds.isEmpty) return;

      // 3. Prepare batch notification records
      final notificationRows = targetUserIds.map((targetUid) => {
        'user_id': targetUid,
        'actor_id': _currentUid,
        'type': 'MENTION',
        'thread_id': threadId,
        'content': isComment ? 'mentioned you in a comment' : 'mentioned you in a post',
        'is_read': false,
      }).toList();

      // 4. Atomic batch insertion
      await _supabase.from('notifications').insert(notificationRows);
      debugPrint('[Mentions] Successfully batch inserted ${notificationRows.length} mention notifications for thread: $threadId');
    } catch (e) {
      debugPrint('[Mentions] Error sending mention notifications batch: $e');
    }
  }

}
