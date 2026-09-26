part of '../database_service.dart';

extension UnreadExtension on DatabaseService {
  // --- Unread Count Handlers ---

  Future<void> fetchUnreadCounts() async {
    if (_currentUid.isEmpty) return;
    try {
      final msgResponse = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', _currentUid)
          .eq('is_read', false);
      _unreadMessagesCount = (msgResponse as List<dynamic>).length;

      final notifResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _currentUid)
          .eq('is_read', false);
      _unreadNotificationsCount = (notifResponse as List<dynamic>).length;

      updateState();
    } catch (e) {
      debugPrint("Fetch unread counts error: $e");
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> msg) async {
    final senderProfile = await fetchProfile(msg['sender_id'] as String);
    final senderName = senderProfile?.fullName ?? "Someone";
    final rawContent = msg['content'] as String? ?? '';

    String body;
    if (rawContent.startsWith('E2EE:v1:')) {
      final senderPublicKey = senderProfile?.publicKey;
      if (senderPublicKey != null && senderPublicKey.isNotEmpty) {
        try {
          final parts = rawContent.split(':');
          if (parts.length == 5) {
            final nonceBase64 = parts[2];
            final macBase64 = parts[3];
            final cipherTextBase64 = parts[4];
            final decrypted = await sl<E2EEService>().decryptMessage(
              cipherTextBase64,
              nonceBase64,
              macBase64,
              senderPublicKey,
            );
            body = (decrypted != null && decrypted.isNotEmpty) ? decrypted : 'Sent you a message';
          } else {
            body = 'Sent you a message';
          }
        } catch (e) {
          debugPrint('Notification decryption error: $e');
          body = 'Sent you a message';
        }
      } else {
        body = 'Sent you a message';
      }
    } else {
      if (rawContent.startsWith('{') && rawContent.contains('"text"')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(rawContent);
          body = parsed['text'] as String? ?? rawContent;
        } catch (e) {
          body = rawContent.isNotEmpty ? rawContent : '📷 Photo';
        }
      } else {
        body = rawContent.isNotEmpty ? rawContent : '📷 Photo';
      }
    }

    final activeId = currentActiveChatUserId?.trim().toLowerCase();
    final senderIdStr = (msg['sender_id'] as String?)?.trim();
    final isInsideCurrentChat = activeId != null &&
        activeId.isNotEmpty &&
        senderIdStr != null &&
        senderIdStr.toLowerCase() == activeId;

    if (!isInsideCurrentChat && senderIdStr != null) {
      // Play chime sound only when OUTSIDE this chat
      sl<PlaySoundUseCase>().call(SoundType.chime);
  
      // Typed push notification — goes to Messages channel with grouping
      await sl<ShowNotificationUseCase>().call(
        type: NotificationType.message,
        id: senderIdStr.hashCode,
        senderName: senderName,
        message: body,
        payload: 'message:$senderIdStr',
      );
    } else if (senderIdStr != null) {
      // User is already inside this chat, ensure notification tray is cleared and mark as read immediately
      LocalNotificationService.cancelNotification(senderIdStr.hashCode);
      markMessagesAsRead(senderIdStr);
    }

    _incomingNotificationStreamController.add({
      'title': senderName,
      'body': body,
      'type': 'message',
      'sender_id': msg['sender_id'],
      'profile': senderProfile,
      'created_at': msg['created_at'],
    });
  }

  void _handleIncomingNotification(Map<String, dynamic> notif) async {
    final type = (notif['type'] as String? ?? '').toLowerCase();
    final actorId = notif['actor_id'] as String?;

    // Anti-Spam & User Preferences Check: Respect user's settings for this notification type
    final notifSettings = NotificationSettingsProvider();
    final shouldShow = notifSettings.shouldNotify(
      type: type,
      isPush: false,
      actorId: actorId,
      followingIds: _followingIds.toList(),
    );

    if (!shouldShow) {
      debugPrint('[unread_ext] Suppressed in-app notification for type "$type" per user settings.');
      return;
    }

    final actorProfile = actorId != null ? await fetchProfile(actorId) : null;
    final actorName = actorProfile?.fullName ?? "Someone";
    final content = notif['content'] as String? ?? '';
    final threadId = notif['thread_id'] as String?;

    // Play chime sound
    sl<PlaySoundUseCase>().call(SoundType.chime);

    // Route to typed notification helper for proper OS grouping
    final id = notif['id'].hashCode;
    final payload = threadId != null ? 'thread:$threadId' : 'notification';

    switch (type) {
      case 'follow':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.follow,
          id: id,
          actorName: actorName,
          payload: 'profile:${notif['actor_id']}',
        );
        break;
      case 'like':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.like,
          id: id,
          actorName: actorName,
          postSnippet: content.isNotEmpty ? content : 'your post',
          payload: payload,
        );
        break;
      case 'mention':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.mention,
          id: id,
          actorName: actorName,
          snippet: content,
          payload: payload,
        );
        break;
      default: // comment, repost, reply, etc.
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.activity,
          id: id,
          actorName: actorName,
          action: content,
          payload: payload,
        );
    }

    _incomingNotificationStreamController.add({
      'title': actorName,
      'body': content,
      'type': type,
    });
  }

}
