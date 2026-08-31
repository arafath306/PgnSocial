import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'local_notification_service.dart';
import 'database_service.dart';

// Helper to route notification display based on notification type
Future<void> _displayNotification({
  required int id,
  required String title,
  required String body,
  required String type,
  String? payload,
}) async {
  switch (type) {
    case 'message':
      await LocalNotificationService.showMessageNotification(
        id: id,
        senderName: title,
        message: body,
        payload: payload,
      );
      break;
    case 'like':
      await LocalNotificationService.showLikeNotification(
        id: id,
        actorName: title,
        postSnippet: body,
        payload: payload,
      );
      break;
    case 'follow':
      await LocalNotificationService.showFollowNotification(
        id: id,
        actorName: title,
        payload: payload,
      );
      break;
    case 'mention':
      await LocalNotificationService.showMentionNotification(
        id: id,
        actorName: title,
        snippet: body,
        payload: payload,
      );
      break;
    default:
      await LocalNotificationService.showActivityNotification(
        id: id,
        actorName: title,
        action: body,
        payload: payload,
      );
      break;
  }
}

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  final notification = message.notification;
  if (notification != null) {
    await LocalNotificationService.initialize();
    await _displayNotification(
      id: message.hashCode,
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      type: message.data['type'] ?? 'activity',
      payload: message.data['payload'],
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Local Notification System Tray Service
    await LocalNotificationService.initialize();

    // 2. Request Permission (Required for Android 13+ & iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push notification permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 3. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'Dak Notification';
      final body = notification?.body ?? message.data['body'] ?? '';
      final channelId = message.data['channel_id'] as String?;
      final type = message.data['type'] ?? (channelId == 'pigeon_messages' ? 'message' : 'activity');

      // Check if user is actively chatting with the sender
      final activeChatId = DatabaseService.activeChatUserId;
      if (activeChatId != null && activeChatId.isNotEmpty) {
        final senderId = message.data['sender_id'] ??
            message.data['senderId'] ??
            message.data['tag'] ??
            message.data['userId'];

        if (type == 'message' || channelId == 'pigeon_messages') {
          if (senderId != null && senderId.toString() == activeChatId) {
            debugPrint('[PushNotificationService] Suppressed notification for active chat user: $senderId');
            return; // Suppress notification since user is inside this exact chat!
          }
        }
      }

      if (body.isNotEmpty || notification != null) {
        await _displayNotification(
          id: message.hashCode,
          title: title,
          body: body,
          type: type,
          payload: message.data['payload'],
        );
      }
    });

    // 5. Update Token in Supabase
    await _syncToken();
    _fcm.onTokenRefresh.listen((newToken) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _saveTokenToDatabase(newToken, user.id);
      }
    });

    _initialized = true;
  }

  Future<void> _syncToken() async {
    try {
      String? token;
      
      // APNS for iOS is required before fetching FCM token
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          token = await _fcm.getToken();
        } else {
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await _fcm.getAPNSToken();
          if (apnsToken != null) token = await _fcm.getToken();
        }
      } else {
        token = await _fcm.getToken();
      }

      if (token != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await _saveTokenToDatabase(token, userId);
        }
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint("FCM token saved successfully");
    } catch (e) {
      debugPrint("Error saving FCM token to Supabase: $e");
    }
  }
}
