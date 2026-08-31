import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/audio_waveform_widget.dart';

import 'dart:typed_data';

class ChatVoicePlayer extends StatefulWidget {
  final String? audioUrl;
  final Uint8List? audioBytes;
  final bool isMe;

  const ChatVoicePlayer({
    super.key,
    this.audioUrl,
    this.audioBytes,
    required this.isMe,
  });

  @override
  State<ChatVoicePlayer> createState() => _ChatVoicePlayerState();
}

class _ChatVoicePlayerState extends State<ChatVoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isBuffering = false;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    try {
      if (widget.audioBytes != null) {
        await _player.setSourceBytes(widget.audioBytes!);
      } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player.setSourceUrl(widget.audioUrl!);
      }
    } catch (e) {
      debugPrint("Error setting audio source: $e");
    }
  }

  @override
  void didUpdateWidget(ChatVoicePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioUrl != oldWidget.audioUrl &&
        widget.audioUrl != null &&
        widget.audioUrl!.isNotEmpty) {
      _player.setSourceUrl(widget.audioUrl!);
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _player.setPlaybackRate(_playbackSpeed);
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          await _player.seek(Duration.zero);
        }
        if (widget.audioBytes != null) {
          await _player.play(BytesSource(widget.audioBytes!));
        } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
          await _player.play(UrlSource(widget.audioUrl!));
        }
      }
    } catch (e) {
      debugPrint("Error toggling play: $e");
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? Colors.white : Colors.black87;
    final iconColor = widget.isMe ? const Color(0xFF1E824C) : Colors.blue;
    final activeColor = widget.isMe ? Colors.white : const Color(0xFF1E824C);
    final inactiveColor = widget.isMe ? Colors.white38 : Colors.black12;

    final double progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Circle Button
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: widget.isMe ? Colors.white : Colors.blue.withValues(alpha: 0.1),
              child: _isBuffering
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: iconColor,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Waveform & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AudioWaveformWidget(
                  progress: progress,
                  seedKey: widget.audioUrl,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  barCount: 22,
                  height: 24,
                  onSeek: (fraction) {
                    if (_duration.inMilliseconds > 0) {
                      final targetMs = (fraction * _duration.inMilliseconds).toInt();
                      _player.seek(Duration(milliseconds: targetMs));
                    }
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
                      style: GoogleFonts.inter(
                        color: fgColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _togglePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF1E824C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_playbackSpeed.toStringAsFixed(_playbackSpeed == 1.0 || _playbackSpeed == 2.0 ? 0 : 1)}x',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: fgColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
