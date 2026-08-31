import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/message_entity.dart';

class LocalChatDatabase {
  static final LocalChatDatabase instance = LocalChatDatabase._init();
  static Database? _database;

  LocalChatDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_messages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN reactions TEXT');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN is_pinned INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE messages ADD COLUMN pinned_at TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT,
        receiver_id TEXT,
        text TEXT,
        time TEXT,
        created_at TEXT,
        media_url TEXT,
        media_type TEXT,
        is_read INTEGER,
        reply_to_id TEXT,
        reply_to_text TEXT,
        reply_to_sender TEXT,
        room_id TEXT,
        reactions TEXT,
        is_pinned INTEGER DEFAULT 0,
        pinned_at TEXT
      )
    ''');
    
    // Index on room_id and created_at for fast queries
    await db.execute('CREATE INDEX idx_room_id ON messages (room_id)');
    await db.execute('CREATE INDEX idx_created_at ON messages (created_at)');
  }

  String _getRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> cacheMessage(MessageEntity msg, String currentUid, String otherUserId) async {
    final db = await instance.database;
    final roomId = _getRoomId(currentUid, otherUserId);
    
    await db.insert(
      'messages',
      {
        'id': msg.id,
        'sender_id': msg.isMe ? currentUid : otherUserId,
        'receiver_id': msg.isMe ? otherUserId : currentUid,
        'text': msg.text,
        'time': msg.time,
        'created_at': msg.createdAt,
        'media_url': msg.mediaUrl,
        'media_type': msg.mediaType,
        'is_read': msg.isRead ? 1 : 0,
        'reply_to_id': msg.replyToId,
        'reply_to_text': msg.replyToText,
        'reply_to_sender': msg.replyToSender,
        'room_id': roomId,
        'reactions': msg.reactions != null ? jsonEncode(msg.reactions) : null,
        'is_pinned': msg.isPinned ? 1 : 0,
        'pinned_at': msg.pinnedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheMessages(List<MessageEntity> messages, String currentUid, String otherUserId) async {
    final db = await instance.database;
    final roomId = _getRoomId(currentUid, otherUserId);
    
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'messages',
        {
          'id': msg.id,
          'sender_id': msg.isMe ? currentUid : otherUserId,
          'receiver_id': msg.isMe ? otherUserId : currentUid,
          'text': msg.text,
          'time': msg.time,
          'created_at': msg.createdAt,
          'media_url': msg.mediaUrl,
          'media_type': msg.mediaType,
          'is_read': msg.isRead ? 1 : 0,
          'reply_to_id': msg.replyToId,
          'reply_to_text': msg.replyToText,
          'reply_to_sender': msg.replyToSender,
          'room_id': roomId,
          'reactions': msg.reactions != null ? jsonEncode(msg.reactions) : null,
          'is_pinned': msg.isPinned ? 1 : 0,
          'pinned_at': msg.pinnedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageEntity>> getCachedMessages(String currentUid, String otherUserId) async {
    final db = await instance.database;
    final roomId = _getRoomId(currentUid, otherUserId);
    
    final maps = await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) {
      Map<String, String>? reactions;
      if (map['reactions'] != null && (map['reactions'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(map['reactions'] as String);
          if (decoded is Map) {
            reactions = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {}
      }

      return MessageEntity(
        id: map['id'] as String,
        text: map['text'] as String,
        isMe: map['sender_id'] == currentUid,
        time: map['time'] as String,
        createdAt: map['created_at'] as String,
        mediaUrl: map['media_url'] as String?,
        mediaType: map['media_type'] as String?,
        isRead: (map['is_read'] as int) == 1,
        replyToId: map['reply_to_id'] as String?,
        replyToText: map['reply_to_text'] as String?,
        replyToSender: map['reply_to_sender'] as String?,
        reactions: reactions,
        isPinned: (map['is_pinned'] as int? ?? 0) == 1,
        pinnedAt: map['pinned_at'] as String?,
      );
    }).toList();
  }

  Future<void> deleteMessage(String id) async {
    final db = await instance.database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('messages');
  }
}
