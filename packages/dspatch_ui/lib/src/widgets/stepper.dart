import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pulsing_dot.dart';

/// A horizontal step-progress indicator.
///
/// Shows [totalSteps] circles connected by lines. Steps before [currentStep]
/// are marked completed (checkmark), the current step pulses, and remaining
/// steps are empty.
class DspatchStepper extends StatelessWidget {
  /// Total number of steps.
  final int totalSteps;

  /// Current step (1-based). Steps before this are completed.
  final int currentStep;

  /// Number of steps that have been completed (0-based count).
  /// Defaults to `currentStep - 1`.
  final int? completedSteps;

  /// Whether the current step is waiting for user input (shows warning color).
  final bool isWaiting;

  const DspatchStepper({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.completedSteps,
    this.isWaiting = false,
  });

  @override
  Widget build(BuildContext context) {
    final completed = completedSteps ?? (currentStep - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= completed
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
            _StepCircle(
              index: i,
              completed: completed,
              currentStep: currentStep,
              isWaiting: isWaiting,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final int completed;
  final int currentStep;
  final bool isWaiting;

  const _StepCircle({
    required this.index,
    required this.completed,
    required this.currentStep,
    required this.isWaiting,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < completed;
    final isCurrent = index == currentStep - 1 && !isCompleted;

    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: const Icon(LucideIcons.check, size: 14, color: AppColors.success),
      );
    }

    if (isCurrent) {
      return PulsingDot(
        color: isWaiting ? AppColors.warning : AppColors.info,
        label: '${index + 1}',
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
