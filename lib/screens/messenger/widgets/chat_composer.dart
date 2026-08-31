import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/chat_themes.dart';
import '../../../models/profile.dart';
import '../../../services/database_service.dart';
import '../../../widgets/comment_attachment_picker_panel.dart';


class ChatComposer extends StatefulWidget {
  final Map<String, dynamic>? replyingToMessage;
  final Profile realtimeOtherUser;
  final ChatTheme activeTheme;
  final bool showEmojiPanel;
  final int pickerTabIndex;
  final void Function(String text, Map<String, dynamic>? parent) onSend;
  final VoidCallback onPickMedia;
  final VoidCallback onPickCamera;
  final VoidCallback onClearReply;
  final void Function(bool show, int tabIdx) onToggleEmojiPanel;
  final void Function(String gifUrl) onGifSelected;
  final void Function(Uint8List audioBytes)? onSendAudio;

  const ChatComposer({super.key, required this.replyingToMessage,
    required this.realtimeOtherUser,
    required this.activeTheme,
    required this.showEmojiPanel,
    required this.pickerTabIndex,
    required this.onSend,
    required this.onPickMedia,
    required this.onPickCamera,
    required this.onClearReply,
    required this.onToggleEmojiPanel,
    required this.onGifSelected,
    this.onSendAudio,
  });

  @override
  State<ChatComposer> createState() => ChatComposerState();
}

class ChatComposerState extends State<ChatComposer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isTyping = false;
  Timer? _typingBroadcastTimer;
  Timer? _typingStopTimer;

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final _audioRecorder = AudioRecorder();


  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);

      if (has) {
        if (!_isTyping) {
          _isTyping = true;
          Provider.of<DatabaseService>(context, listen: false)
              .sendTypingEvent(widget.realtimeOtherUser.id, true);
              
          _typingBroadcastTimer?.cancel();
          _typingBroadcastTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
            if (mounted) {
              Provider.of<DatabaseService>(context, listen: false)
                  .sendTypingEvent(widget.realtimeOtherUser.id, true);
            }
          });
        }
        _typingStopTimer?.cancel();
        _typingStopTimer = Timer(const Duration(seconds: 2), () {
          if (_isTyping) {
            _isTyping = false;
            _typingBroadcastTimer?.cancel();
            if (mounted) {
              Provider.of<DatabaseService>(context, listen: false)
                  .sendTypingEvent(widget.realtimeOtherUser.id, false);
            }
          }
        });
      } else {
        if (_isTyping) {
          _isTyping = false;
          _typingBroadcastTimer?.cancel();
          _typingStopTimer?.cancel();
          Provider.of<DatabaseService>(context, listen: false)
              .sendTypingEvent(widget.realtimeOtherUser.id, false);
        }
      }
    });
  }

  @override
  void dispose() {
    _typingBroadcastTimer?.cancel();
    _typingStopTimer?.cancel();
    if (_isTyping) {
      Provider.of<DatabaseService>(context, listen: false)
          .sendTypingEvent(widget.realtimeOtherUser.id, false);
    }
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }


  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            bitRate: 24000,
            numChannels: 1,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _recordingSeconds++);
        });
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });
    
    if (cancel && path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }
    
    if (path != null && widget.onSendAudio != null) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        widget.onSendAudio!(bytes);
        await file.delete();
      }
    }
  }

  void _send() {

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, widget.replyingToMessage);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply bar (Floating pill)
          if (widget.replyingToMessage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.border.withValues(alpha: isDark ? 0.3 : 0.6),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.reply, size: 14, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${widget.replyingToMessage!['isMe'] == true ? 'You' : widget.realtimeOtherUser.fullName}: ${widget.replyingToMessage!['text'] ?? ''}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClearReply,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: context.textSecondary),
                  ),
                ],
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
            child: _isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F5F4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: widget.activeTheme.primaryColor, width: 1.5),
                      ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Recording... ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}",
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _stopRecording(cancel: true),
                          child: Icon(Icons.delete_outline, color: context.textSecondary, size: 24),
                        ),
                        const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _stopRecording(cancel: false),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.activeTheme.gradientColors == null ? widget.activeTheme.primaryColor : null,
                                gradient: widget.activeTheme.gradientColors != null ? LinearGradient(colors: widget.activeTheme.gradientColors!) : null,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: context.border.withValues(alpha: isDark ? 0.3 : 0.6),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Emoji Toggle Button (Left)
                        IconButton(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            widget.showEmojiPanel ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                            color: context.textSecondary,
                            size: 24,
                          ),
                          onPressed: () {
                            if (widget.showEmojiPanel) {
                              _focusNode.requestFocus();
                            } else {
                              _focusNode.unfocus();
                            }
                            widget.onToggleEmojiPanel(!widget.showEmojiPanel, 0);
                          },
                        ),
                        
                        // Text Field
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focusNode,
                              onTap: () {
                                if (widget.showEmojiPanel) {
                                  widget.onToggleEmojiPanel(false, 0);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: GoogleFonts.inter(
                                    color: context.textMuted, fontSize: 15),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.only(top: 10, bottom: 10, left: 4, right: 4),
                              ),
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: context.textPrimary),
                              maxLines: 5,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                        ),
                        
                        // Attachment Icons (Right)
                        IconButton(
                          padding: const EdgeInsets.only(bottom: 10, right: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: context.textSecondary,
                            size: 22,
                          ),
                          onPressed: widget.onPickMedia,
                        ),
                          IconButton(
                            padding: const EdgeInsets.only(bottom: 10, right: 12),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.camera_alt_rounded,
                              color: context.textSecondary,
                              size: 22,
                            ),
                            onPressed: widget.onPickCamera,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Mic / Send Button
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.activeTheme.gradientColors == null ? widget.activeTheme.primaryColor : null,
                    gradient: widget.activeTheme.gradientColors != null ? LinearGradient(colors: widget.activeTheme.gradientColors!) : null,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.activeTheme.primaryColor).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_hasText) {
                        _send();
                      } else {
                        _startRecording();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          // Emoji / GIF picker
          if (widget.showEmojiPanel)
            CommentAttachmentPickerPanel(
              initialTabIndex: widget.pickerTabIndex,
              onEmojiSelected: (emoji) {
                final text = _ctrl.text;
                final selection = _ctrl.selection;
                if (!selection.isValid) {
                  _ctrl.text = text + emoji;
                  _ctrl.selection = TextSelection.collapsed(
                      offset: _ctrl.text.length);
                } else {
                  final start = selection.start;
                  final end = selection.end;
                  _ctrl.text = text.replaceRange(start, end, emoji);
                  _ctrl.selection = TextSelection.collapsed(
                      offset: start + emoji.length);
                }
              },
              onGifSelected: (gifUrl) {
                widget.onToggleEmojiPanel(false, 0);
                widget.onGifSelected(gifUrl);
              },
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── Full-screen Media Viewer ───────────────────────────────────────────────