class MessageEntity {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String createdAt;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, String>? reactions;

  MessageEntity({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
    required this.isRead,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.reactions,
  });
}

