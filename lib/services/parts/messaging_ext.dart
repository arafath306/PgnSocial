part of '../database_service.dart';

extension MessagingExtension on DatabaseService {
  // --- Real-time Private Messaging ---

  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return sl<GetMessagesStreamUseCase>()(otherUserId).map((list) {
      return list.map((msg) => {
        'id': msg.id,
        'text': msg.text,
        'isMe': msg.isMe,
        'time': msg.time,
        'created_at': msg.createdAt,
        'media_url': msg.mediaUrl,
        'media_type': msg.mediaType,
        'is_read': msg.isRead,
        'reply_to_id': msg.replyToId,
        'reply_to_text': msg.replyToText,
        'reply_to_sender': msg.replyToSender,
        'reactions': msg.reactions,
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, String content, {String? mediaUrl, String? mediaType}) async {
    if (_blockedUserIds.contains(receiverId)) {
      debugPrint("Cannot send message: User is blocked");
      return;
    }
    final result = await sl<SendMessageUseCase>()(receiverId, content, mediaUrl: mediaUrl, mediaType: mediaType);
    result.fold(
      (failure) => debugPrint("Send message error: ${failure.message}"),
      (_) {
        try {
          FirebaseAnalytics.instance.logEvent(
            name: 'message_sent',
            parameters: {
              'has_media': (mediaUrl != null).toString(),
              'media_type': mediaType ?? 'none',
            },
          );
        } catch (e) {
          debugPrint('Error logging analytics event: $e');
        }
        fetchUnreadCounts();
      },
    );
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    final result = await sl<MarkMessagesAsReadUseCase>()(otherUserId);
    result.fold(
      (failure) => debugPrint("Mark messages as read error: ${failure.message}"),
      (_) => fetchUnreadCounts(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchActiveChats() async {
    final result = await sl<GetActiveChatsUseCase>()();
    return result.fold(
      (failure) {
        debugPrint("Fetch active chats error: ${failure.message}");
        return [];
      },
      (chats) {
        final List<Map<String, dynamic>> list = [];
        for (final chat in chats) {
          final profile = chat['profile'] as Profile;
          if (_blockedUserIds.contains(profile.id)) continue;
          list.add({
            'profile': profile,
            'last_message': chat['lastMessage'],
            'last_message_time': chat['lastMessageTime'],
            'unread_count': chat['unreadCount'],
            'timestamp': DateTime.parse(chat['timeRaw'] as String),
          });
        }
        list.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        return list;
      },
    );
  }

  Future<String?> uploadChatMedia(Uint8List bytes, {String extension = 'jpg', String contentType = 'image/jpeg'}) async {
    final result = await sl<UploadChatMediaUseCase>()(bytes, extension: extension, contentType: contentType);
    return result.fold(
      (failure) {
        debugPrint("Upload chat media error: ${failure.message}");
        return null;
      },
      (url) => url,
    );
  }

  Future<void> updateLastSeen() async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase.from('profiles').update({
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _currentUid);
    } catch (e) {
      debugPrint("Update last seen error: $e");
    }
  }

  Future<bool> deleteConversation(String otherUserId) async {
    final result = await sl<DeleteConversationUseCase>()(otherUserId);
    return result.fold(
      (failure) {
        debugPrint("Delete conversation error: ${failure.message}");
        return false;
      },
      (success) => success,
    );
  }

  void sendTypingEvent(String otherUserId, bool isTyping) {
    if (_currentUid.isEmpty) return;
    sl<IChatRepository>().sendTypingEvent(_currentUid, otherUserId, isTyping);
  }

  Stream<Map<String, dynamic>> getTypingStream(String otherUserId) {
    if (_currentUid.isEmpty) return const Stream.empty();
    return sl<IChatRepository>().getTypingStream(_currentUid, otherUserId);
  }

  Future<bool> editMessage(String messageId, String receiverId, String newContent) async {
    final result = await sl<IChatRepository>().editMessage(messageId, receiverId, newContent);
    return result.fold(
      (failure) {
        debugPrint("Edit message error: ${failure.message}");
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> deleteMessage(String messageId) async {
    final result = await sl<IChatRepository>().deleteMessage(messageId);
    return result.fold(
      (failure) {
        debugPrint("Delete message error: ${failure.message}");
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> toggleMessageReaction(String messageId, String emoji) async {
    final result = await sl<IChatRepository>().toggleReaction(messageId, emoji);
    return result.fold(
      (failure) {
        debugPrint("Toggle reaction error: ${failure.message}");
        return false;
      },
      (_) => true,
    );
  }

}
