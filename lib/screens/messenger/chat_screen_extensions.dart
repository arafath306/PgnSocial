// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'chat_screen.dart';

extension ChatScreenExtensions on _ChatScreenState {
  void _sendMessage(String text, Map<String, dynamic>? parentMsg) {
    if (text.isEmpty) return;

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'text': text,
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_read': false,
      'is_sending': true,
      if (parentMsg != null) ...{
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'],
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
      }
    };

    setState(() {
      _pendingMessages.add(tempMsg);
      _replyingToMessage = null;
      _showEmojiPanel = false;
    });
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    String contentToSave = text;
    if (parentMsg != null) {
      contentToSave = jsonEncode({
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'] ?? '',
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        'text': text,
      });
    }

    dbService
        .sendMessage(_realtimeOtherUser.id, contentToSave)
        .then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    }).catchError((err) {
      debugPrint('Error sending message: $err');
      if (mounted) {
        setState(() =>
            _pendingMessages.removeWhere((m) => m['id'] == tempId));
        final errorMsg = err.toString().contains("Exception:")
            ? err.toString().replaceAll("Exception: ", "")
            : 'Failed to send message';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: GoogleFonts.inter()),
        ));
      }
    });
  }


  Future<void> _sendMediaMessage() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // Reduced quality to prevent OOM
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isEmpty) return;
      if (!mounted) return;

      // Navigate to preview and edit screen
      final List<Uint8List>? processedBytesList = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(initialImages: images),
        ),
      );

      if (processedBytesList == null || processedBytesList.isEmpty) return;

      for (int i = 0; i < processedBytesList.length; i++) {
        final bytes = processedBytesList[i];
        final parentMsg = _replyingToMessage;
        final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_$i';

        final tempMsg = {
          'id': tempId,
          'text': '',
          'isMe': true,
          'time': _formatToDhaka12Hr(DateTime.now()),
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'is_read': false,
          'is_sending': true,
          'local_media_bytes': bytes,
          'media_type': 'image',
          if (parentMsg != null) ...{
            'reply_to_id': parentMsg['id'],
            'reply_to_text': parentMsg['text'],
            'reply_to_sender':
                parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
          }
        };

        if (mounted) {
          setState(() {
            _pendingMessages.add(tempMsg);
            _replyingToMessage = null; // Clear reply quote after first image
            _showEmojiPanel = false;
          });
          _scrollToBottom();
        }

        dbService.uploadChatMedia(bytes).then((mediaUrl) async {
          if (mediaUrl != null) {
            if (mounted) {
              setState(() {
                final idx =
                    _pendingMessages.indexWhere((m) => m['id'] == tempId);
                if (idx != -1) _pendingMessages[idx]['media_url'] = mediaUrl;
              });
            }
            String contentToSave = '';
            if (parentMsg != null) {
              contentToSave = jsonEncode({
                'reply_to_id': parentMsg['id'],
                'reply_to_text': parentMsg['text'] ?? '',
                'reply_to_sender': parentMsg['isMe'] == true
                    ? 'You'
                    : _realtimeOtherUser.fullName,
                'text': '',
              });
            }
            await dbService.sendMessage(_realtimeOtherUser.id, contentToSave,
                mediaUrl: mediaUrl, mediaType: 'image');
          } else {
            throw Exception('Media upload returned null');
          }
        }).then((_) {
          if (mounted) {
            setState(() {
              final idx =
                  _pendingMessages.indexWhere((m) => m['id'] == tempId);
              if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
            });
          }
        }).catchError((err) {
          debugPrint('Error sending media: $err');
          if (mounted) {
            setState(() =>
                _pendingMessages.removeWhere((m) => m['id'] == tempId));
            final errorMsg = err.toString().contains("Exception:")
                ? err.toString().replaceAll("Exception: ", "")
                : 'Failed to send image.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(errorMsg, style: GoogleFonts.inter()),
              backgroundColor: Colors.redAccent,
            ));
          }
        });

        // Add a tiny delay between starting uploads to avoid identical timestamp IDs
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }


  Future<void> _sendCameraMessage() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Reduced quality to prevent OOM
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image == null) return;
      if (!mounted) return;

      // Navigate to preview and edit screen
      final List<Uint8List>? processedBytesList = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(initialImages: [image]),
        ),
      );

      if (processedBytesList == null || processedBytesList.isEmpty) return;

      final bytes = processedBytesList.first;
      final parentMsg = _replyingToMessage;
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      final tempMsg = {
        'id': tempId,
        'text': '',
        'isMe': true,
        'time': _formatToDhaka12Hr(DateTime.now()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
        'is_sending': true,
        'local_media_bytes': bytes,
        'media_type': 'image',
        if (parentMsg != null) ...{
          'reply_to_id': parentMsg['id'],
          'reply_to_text': parentMsg['text'],
          'reply_to_sender':
              parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        }
      };

      if (mounted) {
        setState(() {
          _pendingMessages.add(tempMsg);
          _replyingToMessage = null;
          _showEmojiPanel = false;
        });
        _scrollToBottom();
      }

      dbService.uploadChatMedia(bytes).then((mediaUrl) async {
        if (mediaUrl != null) {
          if (mounted) {
            setState(() {
              final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
              if (idx != -1) _pendingMessages[idx]['media_url'] = mediaUrl;
            });
          }
          String contentToSave = '';
          if (parentMsg != null) {
            contentToSave = jsonEncode({
              'reply_to_id': parentMsg['id'],
              'reply_to_text': parentMsg['text'] ?? '',
              'reply_to_sender': parentMsg['isMe'] == true
                  ? 'You'
                  : _realtimeOtherUser.fullName,
              'text': '',
            });
          }
          await dbService.sendMessage(_realtimeOtherUser.id, contentToSave,
              mediaUrl: mediaUrl, mediaType: 'image');
        } else {
          throw Exception('Media upload returned null');
        }
      }).then((_) {
        if (mounted) {
          setState(() {
            final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
            if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
          });
        }
      }).catchError((err) {
        debugPrint('Error sending camera media: $err');
        if (mounted) {
          setState(() => _pendingMessages.removeWhere((m) => m['id'] == tempId));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to send image.', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ));
        }
      });
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
  }


  Future<void> _sendAudioMessage(Uint8List bytes) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final parentMsg = _replyingToMessage;
      final String tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}';

      final tempMsg = {
        'id': tempId,
        'text': '',
        'isMe': true,
        'time': _formatToDhaka12Hr(DateTime.now()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
        'is_sending': true,
        'local_media_bytes': bytes,
        'media_type': 'audio',
        if (parentMsg != null) ...{
          'reply_to_id': parentMsg['id'],
          'reply_to_text': parentMsg['text'],
          'reply_to_sender':
              parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        }
      };

      if (mounted) {
        setState(() {
          _pendingMessages.add(tempMsg);
          _replyingToMessage = null; 
          _showEmojiPanel = false;
        });
        _scrollToBottom();
      }

      dbService.uploadChatMedia(bytes, extension: 'm4a', contentType: 'audio/m4a').then((mediaUrl) async {
        if (mediaUrl != null) {
          if (mounted) {
            setState(() {
              final idx =
                  _pendingMessages.indexWhere((m) => m['id'] == tempId);
              if (idx != -1) _pendingMessages[idx]['media_url'] = mediaUrl;
            });
          }
          String contentToSave = '';
          if (parentMsg != null) {
            contentToSave = jsonEncode({
              'reply_to_id': parentMsg['id'],
              'reply_to_text': parentMsg['text'] ?? '',
              'reply_to_sender': parentMsg['isMe'] == true
                  ? 'You'
                  : _realtimeOtherUser.fullName,
              'text': '',
            });
          }
          await dbService.sendMessage(_realtimeOtherUser.id, contentToSave,
              mediaUrl: mediaUrl, mediaType: 'audio');
        } else {
          throw Exception('Media upload returned null');
        }
      }).then((_) {
        if (mounted) {
          setState(() {
            final idx =
                _pendingMessages.indexWhere((m) => m['id'] == tempId);
            if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
          });
        }
      }).catchError((error) {
        debugPrint('Error sending audio message: $error');
        if (mounted) {
          setState(() {
            _pendingMessages.removeWhere((m) => m['id'] == tempId);
          });
          final errorMsg = error.toString().contains("Exception:")
              ? error.toString().replaceAll("Exception: ", "")
              : 'Failed to send audio message.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ));
        }
      });
    } catch (e) {
      debugPrint('Error in _sendAudioMessage: $e');
    }
  }


  void _sendGifMessage(String gifUrl) {
    final parentMsg = _replyingToMessage;
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMsg = {
      'id': tempId,
      'text': '',
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_read': false,
      'is_sending': true,
      'media_url': gifUrl,
      'media_type': 'image',
      if (parentMsg != null) ...{
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'],
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
      }
    };

    setState(() {
      _pendingMessages.add(tempMsg);
      _replyingToMessage = null;
      _showEmojiPanel = false;
    });
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    String contentToSave = '';
    if (parentMsg != null) {
      contentToSave = jsonEncode({
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'] ?? '',
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        'text': '',
      });
    }

    dbService
        .sendMessage(_realtimeOtherUser.id, contentToSave,
            mediaUrl: gifUrl, mediaType: 'image')
        .then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    }).catchError((err) {
      debugPrint('Error sending GIF: $err');
      if (mounted) {
        setState(() =>
            _pendingMessages.removeWhere((m) => m['id'] == tempId));
        final errorMsg = err.toString().contains("Exception:")
            ? err.toString().replaceAll("Exception: ", "")
            : 'Failed to send GIF.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
        ));
      }
    });
  }


  void _showEditMessageDialog(String messageId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Edit Message',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          style: GoogleFonts.inter(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: GoogleFonts.inter(color: context.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              Navigator.pop(ctx);

              // Optimistic UI update
              setState(() {
                for (final msg in _allMessages) {
                  if (msg['id'] == messageId) {
                    msg['text'] = newText;
                    break;
                  }
                }
              });

              final dbService =
                  Provider.of<DatabaseService>(context, listen: false);
              final ok = await dbService.editMessage(
                  messageId, _realtimeOtherUser.id, newText);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Failed to edit message.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            child: Text('Save',
                style: GoogleFonts.inter(
                    color: context.primaryAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Delete Message?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Optimistically hide the message immediately
              setState(() {
                _deletedIds.add(messageId);
                _pendingMessages.removeWhere((m) => m['id'] == messageId);
              });

              final dbService =
                  Provider.of<DatabaseService>(context, listen: false);
              final ok = await dbService.deleteMessage(messageId);
              if (!ok && mounted) {
                // Revert on failure
                setState(() => _deletedIds.remove(messageId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Failed to delete message.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showMessageActionMenu(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'] as bool;
    final String? text = msg['text'] as String?;
    final String? mediaUrl = msg['media_url'] as String?;
    final String messageId = msg['id'] as String;
    final bool isSending = msg['is_sending'] as bool? ?? false;

    if (isSending) return;

    final myUid = sb.Supabase.instance.client.auth.currentUser?.id;
    String? myReaction;
    if (msg['reactions'] != null && msg['reactions'] is Map && myUid != null) {
      myReaction = (msg['reactions'] as Map)[myUid]?.toString();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Quick Reaction Bar
            ReactionBar(
              currentUserReaction: myReaction,
              onSelectReaction: (emoji) {
                Navigator.pop(ctx);
                _toggleMessageReaction(messageId, emoji);
              },
              onOpenMoreEmojis: () {
                Navigator.pop(ctx);
                _showFullEmojiReactionPicker(messageId, myReaction);
              },
            ),
            // Pin / Unpin
            ListTile(
              leading: Icon(
                Icons.push_pin_rounded,
                color: (msg['is_pinned'] as bool? ?? false)
                    ? Colors.amber
                    : context.primaryAccent,
              ),
              title: Text(
                (msg['is_pinned'] as bool? ?? false)
                    ? 'Unpin message'
                    : 'Pin message',
                style: GoogleFonts.inter(color: context.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _togglePinMessage(
                  messageId,
                  !(msg['is_pinned'] as bool? ?? false),
                );
              },
            ),
            // Reply
            ListTile(
              leading:
                  Icon(Icons.reply_rounded, color: context.primaryAccent),
              title: Text('Reply',
                  style: GoogleFonts.inter(color: context.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingToMessage = msg);
              },
            ),
            // Copy
            if (text != null && text.isNotEmpty)
              ListTile(
                leading:
                    Icon(Icons.copy_rounded, color: context.primaryAccent),
                title: Text('Copy',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ));
                },
              ),
            // Edit (own text messages only)
            if (isMe &&
                text != null &&
                text.isNotEmpty &&
                (mediaUrl == null || mediaUrl.isEmpty))
              ListTile(
                leading:
                    Icon(Icons.edit_rounded, color: context.primaryAccent),
                title: Text('Edit',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditMessageDialog(messageId, text);
                },
              ),
            // Delete
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: Colors.redAccent),
                title: Text('Delete',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(messageId);
                },
              ),
            // Report (for other user's messages/media)
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.flag_rounded,
                    color: Colors.orangeAccent),
                title: Text('Report',
                    style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportMessageDialog(messageId);
                },
              ),
            // Download media
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.download_rounded,
                    color: context.primaryAccent),
                title: Text('Download',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadMedia(mediaUrl);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReportMessageDialog(String messageId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report Content',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting this message or picture?',
                style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Inappropriate content, spam, etc.',
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final reason = controller.text.trim();
              try {
                final user = sb.Supabase.instance.client.auth.currentUser;
                await sb.Supabase.instance.client.from('reports').insert({
                  'user_id': user?.id,
                  'reason': 'Chat Message/Media Report ($messageId): ${reason.isEmpty ? "Inappropriate media" : reason}',
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Report chat message error: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Submit Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _confirmBlockUser() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Block User?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to block ${widget.otherUser.fullName}?',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final settings =
                  Provider.of<GeneralSettingsProvider>(context, listen: false);
              await settings.blockUserById(widget.otherUser.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${widget.otherUser.fullName} has been blocked.'),
                  backgroundColor: Colors.redAccent,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Block',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }


  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Delete Conversation?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to delete all messages? This action is permanent.',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db =
                  Provider.of<DatabaseService>(context, listen: false);
              final success =
                  await db.deleteConversation(widget.otherUser.id);
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed to delete conversation.'),
                    backgroundColor: Colors.orangeAccent,
                  ));
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }


  void _showMessengerProfile() {
    final sharedMedia = _allMessages
        .where((m) =>
            m['media_url'] != null && (m['media_url'] as String).isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MessengerProfileSheet(
        otherUser: widget.otherUser,
        isMuted: _isMuted,
        sharedMedia: sharedMedia,
        onToggleMute: _toggleMute,
        onChangeTheme: () {
          _showThemePicker();
        },
        onBlockUser: () {
          _confirmBlockUser();
        },
        onDeleteConversation: () {
          _confirmDeleteConversation();
        },
        onMediaTapped: (mediaUrl) {
          _openFullScreenMedia(mediaUrl);
        },
      ),
    );
  }

  Future<void> _toggleMessageReaction(String messageId, String emoji) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      await dbService.toggleMessageReaction(messageId, emoji);
    } catch (err) {
      debugPrint('[ChatScreen] Error toggling reaction: $err');
    }
  }

  Future<void> _togglePinMessage(String messageId, bool isPinned) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      final success = await dbService.togglePinMessage(messageId, isPinned);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isPinned ? 'Message pinned' : 'Message unpinned',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: context.primaryAccent,
        ));
      }
    } catch (err) {
      debugPrint('[ChatScreen] Error toggling pin message: $err');
    }
  }

  void _showFullEmojiReactionPicker(String messageId, String? currentReaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'React with any Emoji',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: context.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: AppEmojiPicker(
                    onEmojiSelected: (emoji) {
                      Navigator.pop(ctx);
                      _toggleMessageReaction(messageId, emoji);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
