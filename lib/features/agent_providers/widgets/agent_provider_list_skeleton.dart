// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Skeleton shimmer placeholder for the agent template list.
class AgentProviderListSkeleton extends StatelessWidget {
  const AgentProviderListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: DspatchCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  // Name + description column
                  const Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Skeleton(width: 140, height: 14),
                        SizedBox(height: Spacing.xs),
                        Skeleton(width: 200, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Entry point
                  const Expanded(
                    flex: 2,
                    child: Skeleton(width: 120, height: 12),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Source badge
                  const Skeleton(width: 44, height: 20),
                  const SizedBox(width: Spacing.md),
                  // Time
                  const Skeleton(width: 36, height: 12),
                  const SizedBox(width: Spacing.sm),
                  // Action buttons
                  Skeleton(width: 28, height: 28, borderRadius: AppRadius.sm),
                  const SizedBox(width: Spacing.xs),
                  Skeleton(width: 28, height: 28, borderRadius: AppRadius.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
