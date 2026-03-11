// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// A single step shown in the [GettingStartedBanner].
class GettingStartedStep {
  const GettingStartedStep({
    required this.number,
    required this.title,
    required this.description,
    this.onAction,
    this.actionLabel,
  });

  final int number;
  final String title;
  final String description;
  final VoidCallback? onAction;
  final String? actionLabel;
}

/// Banner that guides new users through numbered steps to get started.
///
/// Replaces the previous [HubHeroBanner]. Accepts a list of [GettingStartedStep]
/// items and renders them as numbered rows inside a [DspatchCard].
class GettingStartedBanner extends StatelessWidget {
  const GettingStartedBanner({super.key, required this.steps});

  final List<GettingStartedStep> steps;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: rocket icon + title
          Row(
            children: const [
              Icon(
                LucideIcons.rocket,
                size: 24,
                color: AppColors.primary,
              ),
              SizedBox(width: Spacing.sm),
              Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Step rows
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number circle
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${step.number}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),

                  // Title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional action button
                  if (step.onAction != null && step.actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(left: Spacing.sm),
                      child: Button(
                        label: step.actionLabel!,
                        size: ButtonSize.sm,
                        onPressed: step.onAction,
                      ),
                    ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}
