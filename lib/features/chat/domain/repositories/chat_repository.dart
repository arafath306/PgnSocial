import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../entities/message_entity.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats();
  Stream<List<MessageEntity>> getMessagesStream(String otherUserId);
  Future<Either<Failure, void>> sendMessage(String receiverId, String content, {String? mediaUrl, String? mediaType});
  Future<Either<Failure, void>> markMessagesAsRead(String otherUserId);
  Future<Either<Failure, bool>> deleteConversation(String otherUserId);
  Future<Either<Failure, String?>> uploadChatMedia(Uint8List bytes, {String extension = 'jpg', String contentType = 'image/jpeg'});
  Future<Either<Failure, void>> editMessage(String messageId, String receiverId, String newContent);
  Future<Either<Failure, void>> deleteMessage(String messageId);
  Future<Either<Failure, void>> toggleReaction(String messageId, String emoji);
  void sendTypingEvent(String currentUserId, String otherUserId, bool isTyping);
  Stream<Map<String, dynamic>> getTypingStream(String currentUserId, String otherUserId);
}
