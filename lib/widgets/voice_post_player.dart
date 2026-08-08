import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'audio_waveform_widget.dart';

class VoicePostPlayer extends StatefulWidget {
  final String audioUrl;
  const VoicePostPlayer({super.key, required this.audioUrl});

  @override
  State<VoicePostPlayer> createState() => _VoicePostPlayerState();
}

class _VoicePostPlayerState extends State<VoicePostPlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.audioUrl);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 0.8),
      ),
      child: Row(
        children: [
          // Play / Pause Circle Button
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                if (_position >= _duration && _duration > Duration.zero) {
                  _audioPlayer.seek(Duration.zero);
                }
                _audioPlayer.play(UrlSource(widget.audioUrl));
              }
            },
            child: CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFF1E824C),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform Visualizer
          Expanded(
            child: AudioWaveformWidget(
              progress: progress,
              seedKey: widget.audioUrl,
              activeColor: const Color(0xFF1E824C),
              inactiveColor: context.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              onSeek: (fraction) {
                if (_duration.inMilliseconds > 0) {
                  final targetMs = (fraction * _duration.inMilliseconds).toInt();
                  _audioPlayer.seek(Duration(milliseconds: targetMs));
                }
              },
            ),
          ),
          const SizedBox(width: 10),

          // Duration Timer
          Text(
            _formatDuration(_isPlaying || _position > Duration.zero ? _position : _duration),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),

          // Playback Speed Toggle Chip (1.0x / 1.5x / 2.0x)
          GestureDetector(
            onTap: _togglePlaybackSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                '${_playbackSpeed.toStringAsFixed(_playbackSpeed == 1.0 || _playbackSpeed == 2.0 ? 0 : 1)}x',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E824C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
