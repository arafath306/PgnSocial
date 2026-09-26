import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'audio_waveform_widget.dart';

class VoicePostPlayer extends StatefulWidget {
  final String audioUrl;
  final bool isCompact;

  const VoicePostPlayer({
    super.key,
    required this.audioUrl,
    this.isCompact = false,
  });

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

    // Light, airy, translucent emerald tint (eliminating the heavy opaque dark box)
    final backgroundColor = context.isDarkMode
        ? const Color(0xFF10B981).withValues(alpha: 0.08)
        : const Color(0xFF10B981).withValues(alpha: 0.05);

    final borderColor = context.isDarkMode
        ? const Color(0xFF10B981).withValues(alpha: 0.22)
        : const Color(0xFF10B981).withValues(alpha: 0.18);

    // High-contrast, crystal-clear waveform colors
    const activeWaveColor = Color(0xFF10B981);
    final inactiveWaveColor = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.32)
        : const Color(0xFF10B981).withValues(alpha: 0.30);

    final playerWidget = Container(
      constraints: widget.isCompact
          ? const BoxConstraints(maxWidth: 260, minWidth: 180)
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 11 : 14,
        vertical: widget.isCompact ? 6.5 : 8.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 22),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
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
              radius: widget.isCompact ? 16 : 18,
              backgroundColor: const Color(0xFF1E824C),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: widget.isCompact ? 18 : 20,
              ),
            ),
          ),
          SizedBox(width: widget.isCompact ? 8 : 11),

          // Waveform Visualizer
          Expanded(
            child: AudioWaveformWidget(
              progress: progress,
              seedKey: widget.audioUrl,
              barCount: widget.isCompact ? 24 : 30,
              height: widget.isCompact ? 22.0 : 28.0,
              activeColor: activeWaveColor,
              inactiveColor: inactiveWaveColor,
              onSeek: (fraction) {
                if (_duration.inMilliseconds > 0) {
                  final targetMs = (fraction * _duration.inMilliseconds).toInt();
                  _audioPlayer.seek(Duration(milliseconds: targetMs));
                }
              },
            ),
          ),
          SizedBox(width: widget.isCompact ? 8 : 9),

          // Duration Timer
          Text(
            _formatDuration(_isPlaying || _position > Duration.zero ? _position : _duration),
            style: GoogleFonts.inter(
              fontSize: widget.isCompact ? 11.5 : 12,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.80)
                  : context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: widget.isCompact ? 7 : 8),

          // Playback Speed Toggle Chip (1.0x / 1.5x / 2.0x)
          GestureDetector(
            onTap: _togglePlaybackSpeed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 6 : 7,
                vertical: widget.isCompact ? 2.5 : 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.38),
                  width: 0.7,
                ),
              ),
              child: Text(
                '${_playbackSpeed.toStringAsFixed(_playbackSpeed == 1.0 || _playbackSpeed == 2.0 ? 0 : 1)}x',
                style: GoogleFonts.inter(
                  fontSize: widget.isCompact ? 10 : 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isCompact) {
      return Align(
        alignment: Alignment.centerLeft,
        child: playerWidget,
      );
    }
    return playerWidget;
  }
}
