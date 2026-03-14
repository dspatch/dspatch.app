// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../../database/engine_database.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';


/// Stats grid showing workspace counts by status.
class WorkspaceStatsGrid extends StatelessWidget {
  const WorkspaceStatsGrid({super.key, required this.workspaces})
      : _loading = false;

  const WorkspaceStatsGrid.loading({super.key})
      : workspaces = const [],
        _loading = true;

  final List<Workspace> workspaces;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? Spacing.sm : 0),
              child: const DspatchCard(
                padding: EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 32, height: 20),
                    SizedBox(height: 4),
                    Skeleton(width: 60, height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final total = workspaces.length;

    return Row(
      children: [
        _StatCard(value: '$total', label: 'Total', icon: LucideIcons.layers),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DspatchCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: Spacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFonts.mono,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
