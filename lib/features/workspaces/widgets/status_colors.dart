// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/agent_state_ext.dart';
import '../../../core/utils/workspace_status.dart';


/// Shared color/variant mappings for agent and workspace statuses.
///
/// Extracted from [AgentHierarchySidebar] and [WorkspaceViewScreen] to
/// eliminate duplication.

Color agentStatusColor(String? status) {
  return switch (status) {
    null => AppColors.muted,
    AgentState.disconnected => AppColors.mutedForeground,
    AgentState.idle => AppColors.mutedForeground,
    AgentState.generating => AppColors.success,
    AgentState.waitingForInquiry => AppColors.warning,
    AgentState.waitingForAgent => AppColors.warning,
    AgentState.completed => AppColors.info,
    AgentState.failed => AppColors.destructive,
    AgentState.crashed => AppColors.destructive,
    _ => AppColors.muted,
  };
}

Color workspaceStatusColor(WorkspaceStatus status) {
  return switch (status) {
    WorkspaceStatus.running => AppColors.success,
    WorkspaceStatus.idle => AppColors.mutedForeground,
    WorkspaceStatus.starting => AppColors.info,
    WorkspaceStatus.stopping => AppColors.warning,
    WorkspaceStatus.failed => AppColors.destructive,
  };
}

BadgeVariant workspaceStatusBadgeVariant(WorkspaceStatus status) {
  return switch (status) {
    WorkspaceStatus.running => BadgeVariant.success,
    WorkspaceStatus.idle => BadgeVariant.secondary,
    WorkspaceStatus.starting => BadgeVariant.primary,
    WorkspaceStatus.stopping => BadgeVariant.warning,
    WorkspaceStatus.failed => BadgeVariant.destructive,
  };
}
