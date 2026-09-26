import 'package:flutter/cupertino.dart';
import '../utils/app_theme.dart';

class ThreadShimmer extends StatefulWidget {
  const ThreadShimmer({super.key});

  @override
  State<ThreadShimmer> createState() => _ThreadShimmerState();
}

class _ThreadShimmerState extends State<ThreadShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final blockColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar skeleton
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text lines skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name line
                          Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Content line 1
                          Container(
                            width: double.infinity,
                            height: 10,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Content line 2
                          Container(
                            width: double.infinity,
                            height: 10,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Content line 3
                          Container(
                            width: 150,
                            height: 10,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions row skeleton
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionIconSkeleton(CupertinoIcons.chat_bubble, baseColor),
                      _buildActionIconSkeleton(CupertinoIcons.arrow_2_circlepath, baseColor),
                      _buildActionIconSkeleton(CupertinoIcons.heart, baseColor),
                      _buildActionIconSkeleton(CupertinoIcons.arrowshape_turn_up_right, baseColor),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionIconSkeleton(IconData icon, Color color) {
    return Icon(
      icon,
      size: 18,
      color: color.withValues(alpha: 0.5),
    );
  }
}
