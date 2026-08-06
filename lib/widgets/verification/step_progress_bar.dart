import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1-based
  final List<String> labels;
  final bool showStepCounter;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.labels,
    this.showStepCounter = true,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStepCounter)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryAccent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 13, color: context.primaryAccent),
                        const SizedBox(width: 5),
                        Text(
                          'Step $currentStep of ${labels.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (currentStep > 0 && currentStep <= labels.length) ? labels[currentStep - 1] : '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final int n = labels.length;
              final double columnWidth = totalWidth / n;
              final double halfColumnWidth = columnWidth / 2;
              
              // Line spans from center of first column to center of last column
              final double lineLeft = halfColumnWidth;
              final double lineRight = halfColumnWidth;
              final double lineWidth = totalWidth - lineLeft - lineRight;
              
              // Active progress width
              double activeProgressWidth = 0.0;
              if (n > 1) {
                final double progressFraction = (currentStep - 1) / (n - 1);
                activeProgressWidth = lineWidth * progressFraction.clamp(0.0, 1.0);
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Background line
                  if (n > 1)
                    Positioned(
                      left: lineLeft,
                  top: 16, // center of 32px circle
                  child: Container(
                    height: 3,
                    width: lineWidth,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),

              // 2. Animated active progress line
              if (n > 1)
                Positioned(
                  left: lineLeft,
                  top: 16, // center of 32px circle
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    height: 3,
                    width: activeProgressWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primaryAccent.withValues(alpha: 0.8),
                          context.primaryAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryAccent.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Step Nodes and Labels
              Row(
                children: List.generate(n, (index) {
                  final stepNumber = index + 1;
                  final isDone = stepNumber < currentStep;
                  final isActive = stepNumber == currentStep;

                  final circleColor = isDone
                      ? context.primaryAccent
                      : (isActive ? context.primaryAccent : (context.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)));

                  final textColor = isDone || isActive
                      ? context.textPrimary
                      : context.textMuted;

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Node Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDone 
                                ? context.primaryAccent 
                                : (isActive 
                                    ? (context.isDarkMode ? const Color(0xFF0F172A) : Colors.white) 
                                    : (context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: circleColor,
                              width: isActive ? 2.5 : 2.0,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: context.primaryAccent.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('check'),
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '$stepNumber',
                                      key: ValueKey('number_$stepNumber'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? context.primaryAccent
                                            : context.textMuted,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

