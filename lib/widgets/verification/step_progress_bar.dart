import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A modern, corporate-grade KYC Segmented Progress Header.
/// Inspired by high-end financial and tech apps like Revolut, Stripe, and Wise.
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1-based index
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

    final int totalSteps = labels.length;
    final int safeCurrentStep = currentStep.clamp(1, totalSteps);
    final String currentLabel = labels[safeCurrentStep - 1];
    final double progressPercent = (safeCurrentStep / totalSteps) * 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Step Pill + Current Step Title + Percentage
          if (showStepCounter) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Step Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.primaryAccent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: context.primaryAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Step $safeCurrentStep of $totalSteps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.primaryAccent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Step Title & Percentage
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${progressPercent.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Corporate Segmented Linear Progress Bars
          Row(
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isPassed = stepNum < safeCurrentStep;
              final isActive = stepNum == safeCurrentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 5.0,
                  ),
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        gradient: (isPassed || isActive)
                            ? LinearGradient(
                                colors: [
                                  context.primaryAccent,
                                  context.primaryAccent.withValues(alpha: 0.85),
                                ],
                              )
                            : null,
                        color: (!isPassed && !isActive)
                            ? (context.isDarkMode
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0))
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: context.primaryAccent.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
