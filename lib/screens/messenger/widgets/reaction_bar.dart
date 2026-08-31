import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_theme.dart';

class ReactionBar extends StatelessWidget {
  final String? currentUserReaction;
  final void Function(String emoji) onSelectReaction;
  final VoidCallback onOpenMoreEmojis;

  static const List<String> defaultEmojis = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '🙏',
    '🔥',
  ];

  const ReactionBar({
    super.key,
    required this.currentUserReaction,
    required this.onSelectReaction,
    required this.onOpenMoreEmojis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: context.border.withValues(alpha: 0.5),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...defaultEmojis.map((emoji) {
            final isSelected = currentUserReaction == emoji;
            return _ReactionButton(
              emoji: emoji,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelectReaction(emoji);
              },
            );
          }),
          const SizedBox(width: 2),
          // More (+) emoji button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onOpenMoreEmojis();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: context.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget renderReactionEmoji(String emoji, {double size = 20}) {
  if (emoji == '❤️' || emoji == '\u2764' || emoji == '\u2764\uFE0F' || emoji == '❤') {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFF3366), Color(0xFFFF0844)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        Icons.favorite_rounded,
        size: size,
        color: Colors.white,
      ),
    );
  }
  return Text(
    emoji,
    style: TextStyle(
      fontSize: size * 0.9,
      fontFamilyFallback: const ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji'],
    ),
  );
}

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSelected
                ? context.primaryAccent.withValues(alpha: 0.25)
                : Colors.transparent,
            border: widget.isSelected
                ? Border.all(color: context.primaryAccent, width: 1.5)
                : null,
          ),
          child: renderReactionEmoji(widget.emoji, size: 26),
        ),
      ),
    );
  }
}
