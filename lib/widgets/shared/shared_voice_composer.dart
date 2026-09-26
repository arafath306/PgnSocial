import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../utils/app_theme.dart';

/// Shared controller to manage voice recording lifecycle, permissions,
/// pause/resume, timer, and audio file generation for both Chat and Comments composers.
class VoiceRecordingController extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordingSeconds => _recordingSeconds;

  String get formattedDuration {
    final minutes = _recordingSeconds ~/ 60;
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        HapticFeedback.mediumImpact();
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/dak_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentRecordingPath = path;

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            bitRate: 24000,
            numChannels: 1,
          ),
          path: path,
        );

        _isRecording = true;
        _isPaused = false;
        _recordingSeconds = 0;
        notifyListeners();

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isPaused) {
            _recordingSeconds++;
            notifyListeners();
          }
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("VoiceRecordingController start error: $e");
      _isRecording = false;
      _isPaused = false;
      _recordingSeconds = 0;
      notifyListeners();
      return false;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_isRecording && !_isPaused) {
        await _audioRecorder.pause();
        _isPaused = true;
        HapticFeedback.selectionClick();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("VoiceRecordingController pause error: $e");
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_isRecording && _isPaused) {
        await _audioRecorder.resume();
        _isPaused = false;
        HapticFeedback.selectionClick();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("VoiceRecordingController resume error: $e");
    }
  }

  Future<void> togglePauseResume() async {
    if (_isPaused) {
      await resumeRecording();
    } else {
      await pauseRecording();
    }
  }

  Future<Uint8List?> stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    HapticFeedback.lightImpact();

    try {
      final isRec = await _audioRecorder.isRecording();
      final isPau = await _audioRecorder.isPaused();
      String? path;
      if (isRec || isPau) {
        path = await _audioRecorder.stop();
      }
      path ??= _currentRecordingPath;

      _isRecording = false;
      _isPaused = false;
      _recordingSeconds = 0;
      _currentRecordingPath = null;
      notifyListeners();

      if (path != null) {
        final file = File(path);
        if (cancel) {
          if (await file.exists()) {
            await file.delete();
          }
          return null;
        }

        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await file.delete();
          if (bytes.isNotEmpty) {
            return bytes;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("VoiceRecordingController stop error: $e");
      _isRecording = false;
      _isPaused = false;
      _recordingSeconds = 0;
      _currentRecordingPath = null;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}

/// Unified Chat Box and Comment Voice Recording Bar UI.
/// Used in both ChatComposer and Comment/Reply Composers with live waveforms,
/// pause/resume push controls, and smooth styling.
class SharedVoiceRecordingBar extends StatefulWidget {
  final int recordingSeconds;
  final bool isPaused;
  final VoidCallback? onPauseResume;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final Color? primaryColor;
  final List<Color>? gradientColors;
  final VoiceRecordingController? controller;

  const SharedVoiceRecordingBar({
    super.key,
    required this.recordingSeconds,
    this.isPaused = false,
    this.onPauseResume,
    required this.onCancel,
    required this.onSend,
    this.primaryColor,
    this.gradientColors,
    this.controller,
  });

  @override
  State<SharedVoiceRecordingBar> createState() => _SharedVoiceRecordingBarState();
}

class _SharedVoiceRecordingBarState extends State<SharedVoiceRecordingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colorPrimary = widget.primaryColor ?? const Color(0xFF1E824C);
    
    final bool effectivePaused = widget.controller?.isPaused ?? widget.isPaused;
    final int effectiveSeconds = widget.controller?.recordingSeconds ?? widget.recordingSeconds;
    
    final minutes = effectiveSeconds ~/ 60;
    final seconds = (effectiveSeconds % 60).toString().padLeft(2, '0');
    final activeColor = effectivePaused ? Colors.amber : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: activeColor.withValues(alpha: effectivePaused ? 0.45 : 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          // Pulsing recording beacon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: effectivePaused ? 0.9 : _pulseAnimation.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.6),
                        blurRadius: effectivePaused ? 3 : 6,
                        spreadRadius: effectivePaused ? 0 : 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Duration Timer
          Text(
            "$minutes:$seconds",
            style: GoogleFonts.jetBrainsMono(
              color: activeColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),

          // Live Animated Sound Waveform Visualizer
          Expanded(
            child: _LiveSoundWaveVisualizer(
              isPaused: effectivePaused,
              accentColor: effectivePaused
                  ? Colors.amber.withValues(alpha: 0.7)
                  : (widget.primaryColor ?? const Color(0xFF1E824C)),
            ),
          ),
          const SizedBox(width: 8),

          // Pause / Resume push button
          GestureDetector(
            onTap: () {
              if (widget.controller != null) {
                widget.controller!.togglePauseResume();
              } else if (widget.onPauseResume != null) {
                widget.onPauseResume!();
              }
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectivePaused
                    ? Colors.amber.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]),
              ),
              child: Icon(
                effectivePaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: effectivePaused
                    ? Colors.amber
                    : (isDark ? Colors.white70 : Colors.black87),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Cancel / Delete recording button
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 21,
            ),
            tooltip: 'Cancel recording',
            onPressed: widget.onCancel,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),

          // Send / Post voice button
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.gradientColors == null ? colorPrimary : null,
                gradient: widget.gradientColors != null
                    ? LinearGradient(colors: widget.gradientColors!)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic live equalizer wave visualizer
class _LiveSoundWaveVisualizer extends StatefulWidget {
  final bool isPaused;
  final Color accentColor;

  const _LiveSoundWaveVisualizer({
    required this.isPaused,
    required this.accentColor,
  });

  @override
  State<_LiveSoundWaveVisualizer> createState() => _LiveSoundWaveVisualizerState();
}

class _LiveSoundWaveVisualizerState extends State<_LiveSoundWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  static const int _barCount = 14;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _LiveSoundWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused && _animController.isAnimating) {
      _animController.stop();
    } else if (!widget.isPaused && !_animController.isAnimating) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value * 2 * math.pi;

        return SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (index) {
              double height;
              if (widget.isPaused) {
                // Settle down neatly when paused
                height = 5.0 + ((index % 3) * 2.0);
              } else {
                // Wave rhythm
                final phase = progress + (index * 0.45);
                final wave = (math.sin(phase) + 1.0) / 2.0;
                final wave2 = (math.cos(phase * 1.5) + 1.0) / 2.0;
                height = 4.0 + (wave * 12.0) + (wave2 * 8.0);
              }

              return Container(
                width: 2.8,
                height: height.clamp(4.0, 24.0),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(
                    alpha: widget.isPaused ? 0.4 : (0.5 + ((index % 4) * 0.12)),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
