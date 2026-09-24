import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../screens/messenger/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/thread_detail_screen.dart';
import '../utils/routes.dart';
import 'database_service.dart';

class NotificationNavigationHandler {
  static Future<void> handlePayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;
    debugPrint('[NotificationNavigation] Handling payload: "$payload"');

    // Wait if the root navigator or context is not yet mounted (e.g. app cold launch)
    BuildContext? context = rootNavigatorKey.currentContext;
    if (context == null) {
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        context = rootNavigatorKey.currentContext;
        if (context != null) break;
      }
    }

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted || rootNavigatorKey.currentState == null) {
      debugPrint('[NotificationNavigation] No active navigator context available.');
      return;
    }

    final db = Provider.of<DatabaseService>(navContext, listen: false);

    try {
      final cleanPayload = payload.trim();

      // ── 1. Message Notification -> Open Chat with Sender ────────────────────
      if (cleanPayload.startsWith('message:')) {
        final senderId = cleanPayload.substring('message:'.length).trim();
        if (senderId.isNotEmpty) {
          final Profile? senderProfile = await db.fetchProfile(senderId);
          if (senderProfile != null && rootNavigatorKey.currentState != null) {
            rootNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(otherUser: senderProfile),
              ),
            );
          }
        }
        return;
      }

      // ── 2. Thread / Post / Mention Notification -> Open Post Detail ──────────
      if (cleanPayload.startsWith('thread:') || cleanPayload.startsWith('post:')) {
        final threadId = cleanPayload.contains(':')
            ? cleanPayload.split(':')[1].trim()
            : cleanPayload;
        if (threadId.isNotEmpty) {
          final ThreadPost? post = await db.fetchSingleThread(threadId);
          if (post != null && rootNavigatorKey.currentState != null) {
            rootNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => ThreadDetailScreen(post: post),
              ),
            );
          }
        }
        return;
      }

      // ── 3. Comment Notification -> Open Post containing that comment ─────────
      if (cleanPayload.startsWith('comment:')) {
        final commentId = cleanPayload.substring('comment:'.length).trim();
        if (commentId.isNotEmpty) {
          final commentData = await db.fetchSingleComment(commentId);
          if (commentData != null) {
            final threadId = commentData['thread_id'] as String?;
            if (threadId != null && threadId.isNotEmpty) {
              final ThreadPost? post = await db.fetchSingleThread(threadId);
              if (post != null && rootNavigatorKey.currentState != null) {
                rootNavigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => ThreadDetailScreen(post: post),
                  ),
                );
              }
            }
          }
        }
        return;
      }

      // ── 4. Profile / Follow Notification -> Open Profile ─────────────────────
      if (cleanPayload.startsWith('profile:')) {
        final userId = cleanPayload.substring('profile:'.length).trim();
        if (userId.isNotEmpty && rootNavigatorKey.currentState != null) {
          rootNavigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: userId),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('[NotificationNavigation] Error navigating to notification target: $e');
    }
  }
}
