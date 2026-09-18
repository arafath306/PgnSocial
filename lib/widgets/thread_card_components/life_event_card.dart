import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/life_event.dart';
import '../../utils/app_theme.dart';

class LifeEventCard extends StatefulWidget {
  final LifeEvent lifeEvent;
  final VoidCallback? onCongratulate;

  const LifeEventCard({
    super.key,
    required this.lifeEvent,
    this.onCongratulate,
  });

  @override
  State<LifeEventCard> createState() => _LifeEventCardState();
}

class _LifeEventCardState extends State<LifeEventCard> with SingleTickerProviderStateMixin {
  bool _isCongratulated = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleCongratulate() {
    setState(() => _isCongratulated = !_isCongratulated);
    _animController.forward(from: 0.0);
    widget.onCongratulate?.call();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.lifeEvent;
    final isDark = context.isDarkMode;
    final isWork = event.isWork;

    // Elegant, premium gradient tailored for Work vs Education
    final gradientColors = isWork
        ? (isDark
            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
            : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)])
        : (isDark
            ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
            : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]);

    final accentColor = isWork ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final borderColor = isWork
        ? (isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE))
        : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0));

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top celebratory badge bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Text(
                  isWork ? '🎉 Career Milestone' : '🎓 Academic Milestone',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? accentColor : Color.lerp(accentColor, Colors.black, 0.2),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white60,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isWork ? 'New Position' : (event.isCurrent ? 'Started Study' : 'Graduated'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big stylish emblem / icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      isWork ? Icons.work_rounded : Icons.school_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      Text(
                        event.title,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Organization Name
                      Text(
                        event.organization,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle & Dates metadata row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (event.subtitle != null && event.subtitle!.isNotEmpty)
                            _metaChip(
                              Icons.badge_outlined,
                              event.subtitle!,
                              context,
                            ),
                          if (event.dateRange.isNotEmpty)
                            _metaChip(
                              Icons.date_range_rounded,
                              event.dateRange,
                              context,
                            ),
                          if (event.location != null && event.location!.isNotEmpty)
                            _metaChip(
                              Icons.location_on_outlined,
                              event.location!,
                              context,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interactive Congratulate Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('👏', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      _isCongratulated ? 'You congratulated!' : 'Celebrate this milestone',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _isCongratulated ? accentColor : context.textMuted,
                      ),
                    ),
                  ],
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: _handleCongratulate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCongratulated
                            ? accentColor
                            : (_isDarker(context) ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCongratulated ? accentColor : borderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (_isCongratulated)
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isCongratulated ? '🎉' : '👏',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isCongratulated ? 'Congratulated' : 'Congratulate',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _isCongratulated
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDarker(BuildContext context) => context.isDarkMode;

  Widget _metaChip(IconData icon, String text, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.textMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: context.textMuted,
          ),
        ),
      ],
    );
  }
}
