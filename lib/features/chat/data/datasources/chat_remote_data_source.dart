import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/security/e2ee_service.dart';
import '../../../../utils/media_compressor.dart';
abstract class ChatRemoteDataSource {
  Future<List<dynamic>> fetchActiveChatsRaw(String currentUserId);
  Future<List<dynamic>> fetchMessagesRaw(String currentUserId, String otherUserId);
  Future<void> sendMessage(String senderId, String receiverId, String content, {String? mediaUrl, String? mediaType});
  Future<void> markMessagesAsRead(String currentUserId, String otherUserId);
  Future<bool> deleteConversation(String currentUserId, String otherUserId);
  Future<String?> uploadChatMedia(String currentUserId, Uint8List bytes, {String extension = 'jpg', String contentType = 'image/jpeg'});
  Stream<sb.PostgresChangePayload> getMessagesRealtimeStream(String otherUserId);
  Future<void> editMessage(String messageId, String senderId, String receiverId, String content);
  Future<void> deleteMessage(String messageId);
  Future<void> toggleReaction(String messageId, String userId, String emoji);
  void sendTypingEvent(String currentUserId, String otherUserId, bool isTyping);
  Stream<Map<String, dynamic>> getTypingStream(String currentUserId, String otherUserId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final sb.SupabaseClient supabaseClient;
  final E2EEService e2eeService;

  ChatRemoteDataSourceImpl(this.supabaseClient, this.e2eeService);

  final Map<String, String?> _publicKeyCache = {};
  final Map<String, sb.RealtimeChannel> _typingChannels = {};

  // Helper method to encrypt content before sending
  Future<String> _encryptContent(String content, String receiverId) async {
    if (content.isEmpty) return content;
    
    try {
      String? receiverPublicKey;
      if (_publicKeyCache.containsKey(receiverId)) {
        receiverPublicKey = _publicKeyCache[receiverId];
      } else {
        final receiverProfile = await supabaseClient.from('profiles').select('public_key').eq('id', receiverId).single();
        receiverPublicKey = receiverProfile['public_key'] as String?;
        _publicKeyCache[receiverId] = receiverPublicKey;
      }
      
      if (receiverPublicKey != null && receiverPublicKey.isNotEmpty) {
        final result = await e2eeService.encryptMessage(content, receiverPublicKey);
        if (result != null) {
          return 'E2EE:v1:${result.nonceBase64}:${result.macBase64}:${result.cipherTextBase64}';
        }
      }
    } catch (e) {
      debugPrint('Encryption failed: $e');
    }
    return content; // Fallback to plain text if encryption fails or receiver has no key
  }

  @override
  Future<List<dynamic>> fetchActiveChatsRaw(String currentUserId) async {
    final response = await supabaseClient
        .from('messages')
        .select('*, sender:profiles!sender_id(*), receiver:profiles!receiver_id(*)')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchMessagesRaw(String currentUserId, String otherUserId) async {
    final response = await supabaseClient
        .from('messages')
        .select()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: false)
        .limit(100);
    final list = response as List<dynamic>;
    return list.reversed.toList();
  }

  @override
  Future<void> sendMessage(String senderId, String receiverId, String content, {String? mediaUrl, String? mediaType}) async {
    final encryptedContent = await _encryptContent(content, receiverId);
    
    await supabaseClient.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': encryptedContent,
      'is_read': false,
      'media_url': ?mediaUrl,
      'media_type': ?mediaType,
    });
  }

  @override
  Future<void> markMessagesAsRead(String currentUserId, String otherUserId) async {
    await supabaseClient
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', otherUserId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
  }

  @override
  Future<bool> deleteConversation(String currentUserId, String otherUserId) async {
    await supabaseClient
        .from('messages')
        .delete()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)');
    return true;
  }

  @override
  Future<String?> uploadChatMedia(String currentUserId, Uint8List bytes, {String extension = 'jpg', String contentType = 'image/jpeg'}) async {
    Uint8List uploadBytes = bytes;
    if (contentType.startsWith('image/')) {
      uploadBytes = await MediaCompressor.compressImageBytes(bytes);
    }
    final path = '$currentUserId/chat_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await supabaseClient.storage.from('avatars').uploadBinary(
      path,
      uploadBytes,
      fileOptions: sb.FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );
    final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  @override
  Stream<sb.PostgresChangePayload> getMessagesRealtimeStream(String otherUserId) {
    final channel = supabaseClient.channel('messages_realtime:$otherUserId');
    final controller = StreamController<sb.PostgresChangePayload>();
    
    final myId = supabaseClient.auth.currentUser?.id ?? '';
    
    final subscription = channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: myId,
      ),
      callback: (payload) {
        if (!controller.isClosed) {
          controller.add(payload);
        }
      },
    ).onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'sender_id',
        value: myId,
      ),
      callback: (payload) {
        if (!controller.isClosed) {
          controller.add(payload);
        }
      },
    ).subscribe();

    controller.onCancel = () {
      supabaseClient.removeChannel(subscription);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> editMessage(String messageId, String senderId, String receiverId, String content) async {
    final encryptedContent = await _encryptContent(content, receiverId);
    await supabaseClient.from('messages').update({
      'content': encryptedContent,
    }).eq('id', messageId);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await supabaseClient.from('messages').delete().eq('id', messageId);
  }

  @override
  Future<void> toggleReaction(String messageId, String userId, String emoji) async {
    try {
      final res = await supabaseClient
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .maybeSingle();
      Map<String, dynamic> reactions = {};
      if (res != null && res['reactions'] != null && res['reactions'] is Map) {
        reactions = Map<String, dynamic>.from(res['reactions'] as Map);
      }
      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }
      await supabaseClient
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('[ChatDataSource] Error toggling reaction: $e');
      rethrow;
    }
  }

  @override
  void sendTypingEvent(String currentUserId, String otherUserId, bool isTyping) {
    // Generate a unique room ID regardless of who is sender/receiver
    final roomIds = [currentUserId, otherUserId]..sort();
    final roomId = 'typing_${roomIds[0]}_${roomIds[1]}';
    
    sb.RealtimeChannel? channel = _typingChannels[roomId];
    if (channel == null) {
      channel = supabaseClient.channel(roomId);
      _typingChannels[roomId] = channel;
      channel.subscribe((status, [error]) {
        if (status == sb.RealtimeSubscribeStatus.subscribed) {
          try {
            channel!.sendBroadcastMessage(
              event: 'typing',
              payload: {'user_id': currentUserId, 'is_typing': isTyping},
            );
          } catch (e) {
      debugPrint('[ChatDataSource] Error sending typing indicator: $e');
    }
        }
      });
      return;
    }

    try {
      channel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': currentUserId, 'is_typing': isTyping},
      );
    } catch (e) {
      // ignore
    }
  }

  @override
  Stream<Map<String, dynamic>> getTypingStream(String currentUserId, String otherUserId) {
    final roomIds = [currentUserId, otherUserId]..sort();
    final roomId = 'typing_${roomIds[0]}_${roomIds[1]}';
    
    final controller = StreamController<Map<String, dynamic>>();
    
    sb.RealtimeChannel? channel = _typingChannels[roomId];
    if (channel == null) {
      channel = supabaseClient.channel(roomId);
      _typingChannels[roomId] = channel;
      channel.subscribe();
    }
    
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        if (!controller.isClosed) {
          controller.add(payload);
        }
      },
    );

    controller.onCancel = () {
      supabaseClient.removeChannel(channel!);
      _typingChannels.remove(roomId);
      controller.close();
    };

    return controller.stream;
  }
}
