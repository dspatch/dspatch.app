// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Skeleton shimmer placeholder for the workspace list.
class WorkspaceListSkeleton extends StatelessWidget {
  const WorkspaceListSkeleton({super.key, this.itemCount = 5});

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
                  // Name + project path
                  const Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Skeleton(width: 140, height: 14),
                        SizedBox(height: Spacing.xs),
                        Skeleton(width: 220, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Agent count
                  const SizedBox(
                    width: 48,
                    child: Skeleton(width: 28, height: 14),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Status badge
                  const Skeleton(width: 50, height: 20),
                  const SizedBox(width: Spacing.md),
                  // Time
                  const Skeleton(width: 36, height: 12),
                  const SizedBox(width: Spacing.sm),
                  // Delete button
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
