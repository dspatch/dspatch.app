// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/providers.dart';

/// Dev-only terminal view showing raw WebSocket frames with roundtrip checks.
class WorkspacePackagesTab extends ConsumerWidget {
  const WorkspacePackagesTab({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<BridgePackageLogEntry>>(
      future: ref.read(sdkProvider).packageInspectorEntries(runId: runId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Spinner());
        }
        if (snapshot.hasError) {
          return ContentArea(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.zero,
            child: EmptyState(
              icon: LucideIcons.package_open,
              title: 'Package Inspector',
              description: 'Error: ${snapshot.error}',
            ),
          );
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const ContentArea(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.zero,
            child: EmptyState(
              icon: LucideIcons.package_open,
              title: 'Package Inspector',
              description: 'No packages captured yet.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.sm),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[entries.length - 1 - index]; // newest first
            final isSent = entry.direction == 'sent';
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Icon(
                      isSent ? LucideIcons.arrow_up : LucideIcons.arrow_down,
                      size: 12,
                      color: isSent
                          ? AppColors.info
                          : AppColors.success,
                    ),
                  ),
                  if (entry.roundtripMismatch)
                    const Padding(
                      padding: EdgeInsets.only(right: Spacing.xs),
                      child: Icon(
                        LucideIcons.triangle_alert,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  if (entry.error != null)
                    const Padding(
                      padding: EdgeInsets.only(right: Spacing.xs),
                      child: Icon(
                        LucideIcons.circle_x,
                        size: 12,
                        color: AppColors.destructive,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      entry.rawJson,
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        color: AppColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
