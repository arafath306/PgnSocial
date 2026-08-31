import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/failures.dart';
import '../../../../models/profile.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/local_chat_db.dart';
import '../../../../core/security/e2ee_service.dart';
import '../../../../utils/chat_themes.dart';

class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final sb.SupabaseClient supabaseClient;
  final E2EEService e2eeService;

  ChatRepositoryImpl(
    this.remoteDataSource,
    this.supabaseClient,
    this.e2eeService,
  );

  // Use Supabase.instance.client for more reliable access during token refresh
  String get _currentUid =>
      sb.Supabase.instance.client.auth.currentUser?.id ??
      supabaseClient.auth.currentUser?.id ??
      '';

  final Map<String, String?> _publicKeyCache = {};
  final Map<String, String> _decryptedCache = {};

  Future<String> _decryptContent(String content, String senderPublicKey) async {
    if (!content.startsWith('E2EE:v1:')) {
      return content;
    }
    final cached = _decryptedCache[content];
    if (cached != null) {
      return cached;
    }
    try {
      final parts = content.split(':');
      if (parts.length == 5) {
        // format: E2EE : v1 : nonce : mac : ciphertext
        final nonceBase64 = parts[2];
        final macBase64 = parts[3];
        final cipherTextBase64 = parts[4];
        final decrypted = await e2eeService.decryptMessage(
          cipherTextBase64,
          nonceBase64,
          macBase64,
          senderPublicKey,
        );
        // If decryption returns null, show empty string (not error)
        final result = decrypted ?? '';
        _decryptedCache[content] = result;
        return result;
      }
    } catch (_) {
      // Silently ignore decrypt errors — show empty string
      return '';
    }
    return content;
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats() async {
    try {
      final data = await remoteDataSource.fetchActiveChatsRaw(_currentUid);
      final Map<String, Map<String, dynamic>> conversations = {};

      // Parallel decrypt the content of each message first
      final decryptedContents = await Future.wait(
        data.map((json) async {
          final senderId = json['sender_id'] as String;
          final isMeSender = senderId == _currentUid;
          final otherUserMap = isMeSender ? json['receiver'] : json['sender'];

          if (otherUserMap == null) return '';
          final otherProfile = Profile.fromJson(
            otherUserMap as Map<String, dynamic>,
          );

          final content = json['content'] as String? ?? '';
          if (content.startsWith('E2EE:v1:') &&
              otherProfile.publicKey != null) {
            return await _decryptContent(content, otherProfile.publicKey!);
          }
          return content;
        }),
      );

      for (int i = 0; i < data.length; i++) {
        final json = data[i];
        final senderId = json['sender_id'] as String;
        final isMeSender = senderId == _currentUid;
        final otherUserMap = isMeSender ? json['receiver'] : json['sender'];

        if (otherUserMap == null) continue;
        final otherProfile = Profile.fromJson(
          otherUserMap as Map<String, dynamic>,
        );
        final otherId = otherProfile.id;
        _publicKeyCache[otherId] = otherProfile.publicKey;

        String content = decryptedContents[i];

        if (content.startsWith('{') &&
            content.endsWith('}') &&
            content.contains('reply_to_id')) {
          try {
            final Map<String, dynamic> jsonReply =
                jsonDecode(content) as Map<String, dynamic>;
            content = jsonReply['text'] as String? ?? '';
          } catch (e) {
            debugPrint('[ChatRepository] Error parsing reply JSON in active chats: $e');
          }
        }

        final String mediaType = json['media_type'] as String? ?? '';
        final String mediaUrl = json['media_url'] as String? ?? '';

        String displayMessage;
        if (mediaType == 'theme_change') {
          if (content.startsWith('custom:')) {
            displayMessage = '🎨 Changed custom theme';
          } else {
            final theme = getChatThemeById(content);
            displayMessage = '🎨 Changed theme to ${theme.name}';
          }
        } else if (mediaType == 'wallpaper_change') {
          if (mediaUrl == 'none' || content == 'none') {
            displayMessage = '🖼️ Removed chat wallpaper';
          } else {
            displayMessage = '🖼️ Changed chat wallpaper';
          }
        } else if (mediaType == 'audio') {
          displayMessage = '🎙️ Voice message';
        } else if (mediaType == 'image') {
          displayMessage = '📷 Photo';
        } else if (content.isNotEmpty) {
          final trimmed = content.trim();
          if (trimmed.startsWith('custom:')) {
            displayMessage = '🎨 Changed custom theme';
          } else if (allChatThemes.any((t) => t.id == trimmed)) {
            final theme = getChatThemeById(trimmed);
            displayMessage = '🎨 Changed theme to ${theme.name}';
          } else if (trimmed == 'none') {
            displayMessage = '🖼️ Removed chat wallpaper';
          } else {
            displayMessage = content;
          }
        } else if (mediaUrl.isNotEmpty) {
          displayMessage = '📷 Photo';
        } else {
          displayMessage = '';
        }

        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = {
            'profile': otherProfile,
            'lastMessage': displayMessage,
            'lastMessageTime': _getRelativeTime(
              DateTime.parse(json['created_at'] as String),
            ),
            'unreadCount':
                (json['is_read'] == false && json['receiver_id'] == _currentUid)
                ? 1
                : 0,
            'timeRaw': json['created_at'] as String,
          };
        } else {
          if (json['is_read'] == false && json['receiver_id'] == _currentUid) {
            conversations[otherId]!['unreadCount'] =
                (conversations[otherId]!['unreadCount'] as int) + 1;
          }
        }
      }

      return Right(conversations.values.toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String otherUserId) {
    final controller = StreamController<List<MessageEntity>>();
    List<MessageEntity> currentMessages = [];
    String? otherPublicKeyVal;

    Future<MessageEntity?> parseMessage(Map<String, dynamic> json) async {
      String text = json['content'] as String? ?? '';
      if (text.startsWith('E2EE:v1:') && otherPublicKeyVal != null) {
        text = await _decryptContent(text, otherPublicKeyVal!);
      }

      final isMe = json['sender_id'] == _currentUid;
      String? replyToId;
      String? replyToText;
      String? replyToSender;

      if (text.startsWith('{') &&
          text.endsWith('}') &&
          text.contains('reply_to_id')) {
        try {
          final Map<String, dynamic> jsonReply =
              jsonDecode(text) as Map<String, dynamic>;
          replyToId = jsonReply['reply_to_id'] as String?;
          replyToText = jsonReply['reply_to_text'] as String?;
          replyToSender = jsonReply['reply_to_sender'] as String?;
          text = jsonReply['text'] as String? ?? '';
        } catch (e) {
          debugPrint('[ChatRepository] Error parsing reply JSON in message stream: $e');
        }
      }

      Map<String, String>? reactions;
      if (json['reactions'] != null && json['reactions'] is Map) {
        reactions = (json['reactions'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      return MessageEntity(
        id: json['id'] as String,
        text: text,
        isMe: isMe,
        time: _getRelativeTime(
          DateTime.parse(json['created_at'] as String),
        ),
        createdAt: json['created_at'] as String,
        mediaUrl: json['media_url'] as String?,
        mediaType: json['media_type'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
        reactions: reactions,
        isPinned: json['is_pinned'] as bool? ?? false,
        pinnedAt: json['pinned_at'] as String?,
      );
    }

    Future<void> loadAndPush() async {
      try {
        // 1. Immediately load from local SQLite cache and push to UI (Instant)
        final localMessages = await LocalChatDatabase.instance.getCachedMessages(_currentUid, otherUserId);
        if (localMessages.isNotEmpty) {
          currentMessages = localMessages;
          if (!controller.isClosed) {
            controller.add(List.from(currentMessages));
          }
        }

        // 2. Fetch public key for decryption if not cached
        if (_publicKeyCache.containsKey(otherUserId)) {
          otherPublicKeyVal = _publicKeyCache[otherUserId];
        } else {
          final otherProfileRes = await supabaseClient
              .from('profiles')
              .select('public_key')
              .eq('id', otherUserId)
              .maybeSingle();
          if (otherProfileRes != null) {
            otherPublicKeyVal = otherProfileRes['public_key'] as String?;
            _publicKeyCache[otherUserId] = otherPublicKeyVal;
          }
        }

        // 3. Fetch from remote in background to sync any new/missing messages
        final data = await remoteDataSource.fetchMessagesRaw(
          _currentUid,
          otherUserId,
        );

        final List<MessageEntity> messages = [];
        for (final json in data) {
          final msg = await parseMessage(json);
          if (msg != null) messages.add(msg);
        }

        // 4. Update local cache with decrypted messages
        if (messages.isNotEmpty) {
          await LocalChatDatabase.instance.cacheMessages(messages, _currentUid, otherUserId);
        }

        // 5. Update UI with fully synced messages
        currentMessages = messages;
        if (!controller.isClosed) {
          controller.add(List.from(currentMessages));
        }
      } catch (e) {
        if (!controller.isClosed && currentMessages.isEmpty) {
          controller.add([]);
        }
      }
    }

    loadAndPush();

    final subscription = remoteDataSource
        .getMessagesRealtimeStream(otherUserId)
        .listen((payload) async {
      final record =
          payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
      if (record.isNotEmpty) {
        final senderId = record['sender_id'] as String?;
        final receiverId = record['receiver_id'] as String?;
        final isRelevant =
            (senderId == _currentUid && receiverId == otherUserId) ||
            (senderId == otherUserId && receiverId == _currentUid);
        if (!isRelevant) {
          return;
        }
      }

      if (payload.eventType == sb.PostgresChangeEvent.insert) {
        final newMsg = await parseMessage(payload.newRecord);
        if (newMsg != null) {
          currentMessages.add(newMsg);
          await LocalChatDatabase.instance.cacheMessage(newMsg, _currentUid, otherUserId);
          if (!controller.isClosed) controller.add(List.from(currentMessages));
        }
      } else if (payload.eventType == sb.PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord['id'] as String;
        currentMessages.removeWhere((m) => m.id == deletedId);
        await LocalChatDatabase.instance.deleteMessage(deletedId);
        if (!controller.isClosed) controller.add(List.from(currentMessages));
      } else if (payload.eventType == sb.PostgresChangeEvent.update) {
        final newMsg = await parseMessage(payload.newRecord);
        if (newMsg != null) {
          final idx = currentMessages.indexWhere((m) => m.id == newMsg.id);
          if (idx != -1) {
            currentMessages[idx] = newMsg;
            await LocalChatDatabase.instance.cacheMessage(newMsg, _currentUid, otherUserId);
            if (!controller.isClosed) controller.add(List.from(currentMessages));
          }
        }
      } else {
        loadAndPush();
      }
    });

    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String receiverId,
    String content, {
    String? mediaUrl,
    String? mediaType,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) return Left(ServerFailure('User not authenticated'));
    try {
      await remoteDataSource.sendMessage(
        uid,
        receiverId,
        content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(String otherUserId) async {
    final uid = _currentUid;
    if (uid.isEmpty) return Left(ServerFailure('User not authenticated'));
    try {
      await remoteDataSource.markMessagesAsRead(uid, otherUserId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteConversation(String otherUserId) async {
    try {
      final result = await remoteDataSource.deleteConversation(
        _currentUid,
        otherUserId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadChatMedia(Uint8List bytes, {String extension = 'jpg', String contentType = 'image/jpeg'}) async {
    try {
      final result = await remoteDataSource.uploadChatMedia(_currentUid, bytes, extension: extension, contentType: contentType);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage(
    String messageId,
    String receiverId,
    String newContent,
  ) async {
    try {
      await remoteDataSource.editMessage(
        messageId,
        _currentUid,
        receiverId,
        newContent,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleReaction(String messageId, String emoji) async {
    final uid = _currentUid;
    if (uid.isEmpty) return Left(ServerFailure('User not authenticated'));
    try {
      await remoteDataSource.toggleReaction(messageId, uid, emoji);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> togglePinMessage(String messageId, bool isPinned) async {
    try {
      await remoteDataSource.togglePinMessage(messageId, isPinned);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _getRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  void sendTypingEvent(String currentUserId, String otherUserId, bool isTyping) {
    remoteDataSource.sendTypingEvent(currentUserId, otherUserId, isTyping);
  }

  @override
  Stream<Map<String, dynamic>> getTypingStream(String currentUserId, String otherUserId) {
    return remoteDataSource.getTypingStream(currentUserId, otherUserId);
  }
}
