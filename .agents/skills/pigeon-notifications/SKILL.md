---
name: pigeon-notifications
description: Use when implementing, modifying, debugging, or reviewing Pigeon's push notifications (FCM/APNs), local tray notifications, notification channels, unread badges, or active chat suppression.
---

# Pigeon Notifications

## Use this skill when

- modifying push notifications delivery via Firebase Cloud Messaging (FCM)
- modifying device-tray local notifications (`flutter_local_notifications v22`)
- changing Android notification channels, sounds, priorities, or grouping
- handling notification payload tap routing in Flutter
- managing FCM token synchronization to Supabase `profiles.fcm_token`
- debugging notification suppression during active chats (`currentActiveChatUserId`)
- modifying decrypt-before-display for incoming E2EE messages
- adding a new notification type or channel
- reviewing Supabase Edge Function `send_auto_push` or database triggers in `push_triggers.sql`
- updating in-app notification queries (`notifications_ext.dart`)

## Do not use this skill when

- modifying user feed algorithms (use `pigeon-social-feed`)
- changing chat UI layouts unrelated to notification triggers
- modifying storage uploads unrelated to notifications

---

## Pigeon Notification Architecture

Pigeon uses a dual-layer notification pipeline:

```
[PostgreSQL Trigger (push_triggers.sql)]
              │
              ▼ (via pg_net)
[Supabase Edge Function: send_auto_push]
              │ (FCM v1 REST API)
              ▼
[Firebase Cloud Messaging (FCM)]
              │
      ┌───────┴────────┐
      ▼                ▼
[Android Device]  [iOS APNs Bridge]
      │                │
      ▼                ▼
[PushNotificationService (Foreground / Background)]
      │
      ├── If message is E2EE: Decrypt with E2EEService
      ├── If user is active in chat (currentActiveChatUserId): Suppress & mark read
      ├── If suppressed: Do not sound / alert
      └── If alertable:
            ├── Play sound via sl<PlaySoundUseCase>() (SoundType.chime)
            └── Show OS tray notification via sl<ShowNotificationUseCase>()
                  │
                  ▼
            [LocalNotificationService (flutter_local_notifications v22)]
                  └── Grouped by channel into InboxStyle summaries
```

---

## Android Channels & Grouping

Defined in `LocalNotificationService` (`lib/services/local_notification_service.dart`):

| Type | Channel ID | Group Key | Summary ID | Priority | Sound |
|------|------------|-----------|------------|----------|-------|
| `message` | `pigeon_messages` | `group_messages` | 1000 | `Importance.max` | ✅ Yes |
| `like` | `pigeon_likes` | `group_likes` | 1001 | `Importance.defaultImportance` | ❌ Silent |
| `follow` | `pigeon_follows` | `group_follows` | 1002 | `Importance.defaultImportance` | ✅ Yes |
| `mention` | `pigeon_mentions` | `group_mentions` | 1003 | `Importance.high` | ✅ Yes |
| `activity` | `pigeon_activity` | `group_activity` | 1004 | `Importance.defaultImportance` | ❌ Silent |

### InboxStyle Notification Grouping
Android 7+ groups notifications per channel to avoid tray spam:
- Each event shows an individual notification (`setAsGroupSummary: false`).
- A summary notification (`setAsGroupSummary: true`, `importance: Importance.min`, `silent: true`) holds the last 5 inbox lines from `_inboxLines`.
- Clear inbox summary lines via `sl<ClearNotificationInboxUseCase>()` or `LocalNotificationService.clearInbox()` when the user opens the app or screen.

---

## Active Chat Suppression & E2EE Message Handling

In `unread_ext.dart` (`_handleIncomingMessage`):

```dart
// 1. E2EE message decryption before notification
if (rawContent.startsWith('E2EE:v1:')) {
  final senderPublicKey = senderProfile?.publicKey;
  if (senderPublicKey != null && senderPublicKey.isNotEmpty) {
    final parts = rawContent.split(':');
    if (parts.length == 5) {
      final decrypted = await sl<E2EEService>().decryptMessage(
        parts[4], parts[2], parts[3], senderPublicKey,
      );
      body = decrypted ?? 'Sent you a message';
    }
  }
}

// 2. Active chat suppression check
if (currentActiveChatUserId != msg['sender_id']) {
  // User is not looking at this chat: play chime & trigger notification
  sl<PlaySoundUseCase>().call(SoundType.chime);
  await sl<ShowNotificationUseCase>().call(
    type: NotificationType.message,
    id: msg['sender_id'].hashCode,
    senderName: senderName,
    message: body,
    payload: 'message:${msg['sender_id']}',
  );
} else {
  // User is already inside this chat: mark as read immediately!
  markMessagesAsRead(msg['sender_id']);
}
```

**Rules:**
- Always check `currentActiveChatUserId` before sounding alerts.
- When suppressed, immediately mark the message as read in Supabase to keep counters accurate.
- Push streams dispatch via `_incomingNotificationStreamController.add(...)`.

---

## FCM Token Lifecycle & iOS APNs

Managed by `PushNotificationService`:

1. **iOS APNs Prerequisite**:
   Never call `_fcm.getToken()` directly on iOS without verifying APNs token first:
   ```dart
   if (Platform.isIOS) {
     String? apnsToken = await _fcm.getAPNSToken();
     if (apnsToken == null) {
       await Future.delayed(const Duration(seconds: 3));
       apnsToken = await _fcm.getAPNSToken();
     }
     if (apnsToken != null) token = await _fcm.getToken();
   } else {
     token = await _fcm.getToken();
   }
   ```
2. **Supabase Token Sync**:
   Whenever a valid token is retrieved or `onTokenRefresh` fires, update `profiles.fcm_token`:
   ```dart
   await _supabase.from('profiles').update({'fcm_token': token}).eq('id', currentUserId);
   ```

---

## Background Message Handler

Must be a **top-level function** annotated with `@pragma('vm:entry-point')`:

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await LocalNotificationService.initialize();
  // Display notification in OS tray
}
```

**Registration:**
Call `FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)` in `main.dart` or during app initialization before other listeners.

---

## Supabase Push Backend Integration

1. **Edge Function**: `supabase/functions/send_auto_push/index.ts`
   - Uses Deno and `jose` (`SignJWT`, `importPKCS8`) to sign Google OAuth2 service account tokens.
   - Posts to FCM v1 endpoint: `https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`.
   - Accepts payload: `{ title, body, fcm_token, tag, channel_id, data }`.
2. **Database Trigger**: `supabase/push_triggers.sql`
   - Uses `pg_net` extension (`net.http_post`) to trigger the Edge Function automatically on `messages` or `comments` insertion if recipient has a non-null `fcm_token`.
   - Skips notifications if commenting on one's own post or message.

---

## In-App Notifications Management

Handled by `NotificationsExtension` in `lib/services/parts/notifications_ext.dart`:
- **Fetch Notifications**:
  ```dart
  final response = await _supabase
      .from('notifications')
      .select('*, actor:profiles!actor_id(*)')
      .eq('user_id', _currentUid)
      .order('created_at', ascending: false);
  ```
- **Mark Read**:
  `markNotificationRead(notificationId)` updates Supabase and decrements `_unreadNotificationsCount`.
- **Mark All Read**:
  `markAllNotificationsRead()` updates all rows where `user_id = _currentUid AND is_read = false`.
