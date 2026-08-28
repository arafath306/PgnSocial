import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../utils/app_theme.dart';

class VoiceRecorderUI extends StatefulWidget {
  final bool isRecording;
  final int recordingSeconds;
  final VoidCallback onToggleRecording;
  final VoidCallback onClose;

  const VoiceRecorderUI({
    super.key,
    required this.isRecording,
    required this.recordingSeconds,
    required this.onToggleRecording,
    required this.onClose,
  });

  @override
  State<VoiceRecorderUI> createState() => _VoiceRecorderUIState();
}

class _VoiceRecorderUIState extends State<VoiceRecorderUI>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _barAnimations;
  final _random = math.Random(42);

  static const int _barCount = 22;
  static const Color _brandGreen = Color(0xFF1E824C);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _barAnimations = List.generate(_barCount, (i) {
      final minH = 0.15 + _random.nextDouble() * 0.1;
      final maxH = 0.45 + _random.nextDouble() * 0.55;
      return Tween<double>(begin: minH, end: maxH).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(
            (i / _barCount) * 0.6,
            ((i / _barCount) * 0.6) + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceRecorderUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _waveController.stop();
      _pulseController.reset();
      _waveController.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B12) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _brandGreen.withValues(alpha: widget.isRecording ? 0.55 : 0.25),
          width: 1.2,
        ),
        boxShadow: widget.isRecording
            ? [
                BoxShadow(
                  color: _brandGreen.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: label + timer + close
          Row(
            children: [
              if (widget.isRecording) ...[
                _RecordingDot(),
                const SizedBox(width: 6),
              ] else
                const Icon(Icons.mic_none_rounded, size: 14, color: _brandGreen),
              const SizedBox(width: 4),
              Text(
                widget.isRecording ? 'Recording' : 'Voice Post',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isRecording ? Colors.redAccent : _brandGreen,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(widget.recordingSeconds),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.isRecording
                      ? Colors.redAccent
                      : (isDark ? Colors.white54 : Colors.black38),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white10 : const Color(0x14000000),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 15,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Centre: waveform bars + mic button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedWaveBars(
                barAnimations: _barAnimations.sublist(0, _barCount ~/ 2),
                barCount: _barCount ~/ 2,
                isRecording: widget.isRecording,
                color: _brandGreen,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: widget.onToggleRecording,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.isRecording)
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isRecording ? Colors.redAccent : _brandGreen,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isRecording ? Colors.redAccent : _brandGreen)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              _AnimatedWaveBars(
                barAnimations: _barAnimations.sublist(_barCount ~/ 2).reversed.toList(),
                barCount: _barCount ~/ 2,
                isRecording: widget.isRecording,
                color: _brandGreen,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            widget.isRecording
                ? 'Tap the button to stop recording'
                : 'Tap the microphone to start recording your voice post',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWaveBars extends StatelessWidget {
  final List<Animation<double>> barAnimations;
  final int barCount;
  final bool isRecording;
  final Color color;

  const _AnimatedWaveBars({
    required this.barAnimations,
    required this.barCount,
    required this.isRecording,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: barAnimations.isNotEmpty ? barAnimations.first : kAlwaysDismissedAnimation,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final height = isRecording
                ? (barAnimations[i].value * 44).clamp(6.0, 44.0)
                : 6.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isRecording ? 0.85 : 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

class _RecordingDot extends StatefulWidget {
  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}
