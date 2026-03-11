// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../di/providers.dart';
import 'workspace_tabs/workspace_files_tab.dart';
import 'workspace_tabs/workspace_info_tab.dart';
import 'workspace_tabs/workspace_inquiries_tab.dart';
import 'workspace_tabs/workspace_logs_tab.dart';
import 'workspace_tabs/workspace_packages_tab.dart';
import 'workspace_tabs/workspace_usage_tab.dart';

/// Workspace-level view with header and tabs: Logs, Usage, Inquiries, Info.
class WorkspaceLevelView extends ConsumerStatefulWidget {
  const WorkspaceLevelView({
    super.key,
    required this.runId,
    required this.workspace,
    required this.agents,
  });

  final String runId;
  final Workspace workspace;
  final List<WorkspaceAgent> agents;

  @override
  ConsumerState<WorkspaceLevelView> createState() =>
      _WorkspaceLevelViewState();
}

class _WorkspaceLevelViewState extends ConsumerState<WorkspaceLevelView> {
  @override
  Widget build(BuildContext context) {
    final pendingCount = ref
            .watch(pendingWorkspaceInquiryCountProvider(widget.workspace.id))
            .valueOrNull ??
        0;

    return DspatchTabs(
      defaultValue: 'logs',
      child: Column(
        children: [
          // ── Header + tabs ──
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  TabsList(
                    children: [
                      const TabsTrigger(
                        value: 'logs',
                        child: Text('Logs'),
                      ),
                      const TabsTrigger(
                        value: 'usage',
                        child: Text('Usage'),
                      ),
                      TabsTrigger(
                        value: 'inquiries',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Inquiries'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: Spacing.xs),
                              DspatchBadge(
                                label: '$pendingCount',
                                variant: BadgeVariant.warning,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const TabsTrigger(
                        value: 'info',
                        child: Text('Info'),
                      ),
                      const TabsTrigger(
                        value: 'files',
                        child: Text('Files'),
                      ),
                      if (kDevMode)
                        const TabsTrigger(
                          value: 'packages',
                          child: Text('Packages'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: Stack(
              children: [
                TabsContent(
                  value: 'logs',
                  child: WorkspaceLogsTab(
                    runId: widget.runId,
                    agents: widget.agents,
                  ),
                ),
                TabsContent(
                  value: 'usage',
                  child: WorkspaceUsageTab(
                    runId: widget.runId,
                    agents: widget.agents,
                  ),
                ),
                TabsContent(
                  value: 'inquiries',
                  child: WorkspaceInquiriesTab(
                    workspaceId: widget.workspace.id,
                  ),
                ),
                TabsContent(
                  value: 'info',
                  child: WorkspaceInfoTab(
                    runId: widget.runId,
                    workspace: widget.workspace,
                    agents: widget.agents,
                  ),
                ),
                TabsContent(
                  value: 'files',
                  child: WorkspaceFilesTab(
                    projectPath: widget.workspace.projectPath,
                  ),
                ),
                if (kDevMode)
                  TabsContent(
                    value: 'packages',
                    child: WorkspacePackagesTab(runId: widget.runId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
