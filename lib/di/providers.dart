// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dspatch_sdk/dspatch_sdk.dart';

import '../features/agent_providers/models/agent_list_item.dart';

// ---------------------------------------------------------------------------
// SDK Instance
// ---------------------------------------------------------------------------

/// The RustSdk facade. Must be overridden in main.dart via
/// `sdkProvider.overrideWithValue(sdk)`.
final sdkProvider = Provider<RustSdk>(
  (_) => throw UnimplementedError('Override sdkProvider in main.dart'),
);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

/// Reactive stream of the full auth state (mode, token scope, user info).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(sdkProvider).watchFullAuthState();
});

/// Current auth mode for UI decisions (anonymous vs connected).
final authModeProvider = Provider<AuthMode>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.mode ??
      AuthMode.undetermined;
});

// ---------------------------------------------------------------------------
// SDK Events
// ---------------------------------------------------------------------------

/// Real-time SDK lifecycle events (agent connected, inquiry created, etc.).
///
/// Consumers filter on their side — the stream contains all event types.
final sdkEventsProvider = StreamProvider<SdkEvent>((ref) {
  return ref.watch(sdkProvider).watchSdkEvents();
});

// ---------------------------------------------------------------------------
// Agent Providers
// ---------------------------------------------------------------------------

final agentProvidersProvider =
    StreamProvider.autoDispose<List<AgentProvider>>((ref) {
  return ref.watch(sdkProvider).watchAgentProviders();
});

final agentProviderProvider = StreamProvider.autoDispose
    .family<AgentProvider?, String>((ref, id) {
  return ref.watch(sdkProvider).watchAgentProvider(id: id);
});

// ---------------------------------------------------------------------------
// Agent Templates
// ---------------------------------------------------------------------------

final agentTemplatesProvider =
    StreamProvider.autoDispose<List<AgentTemplate>>((ref) {
  return ref.watch(sdkProvider).watchAgentTemplates();
});

final agentTemplateProvider = StreamProvider.autoDispose
    .family<AgentTemplate?, String>((ref, id) {
  return ref.watch(sdkProvider).watchAgentTemplate(id: id);
});

// ---------------------------------------------------------------------------
// Merged Agent List (providers + templates)
// ---------------------------------------------------------------------------

final agentListItemsProvider =
    Provider.autoDispose<AsyncValue<List<AgentListItem>>>((ref) {
  final providersAsync = ref.watch(agentProvidersProvider);
  final templatesAsync = ref.watch(agentTemplatesProvider);

  return providersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (providers) => templatesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (templates) {
        final items = [
          ...providers.map(AgentListItem.fromProvider),
          ...templates.map(AgentListItem.fromTemplate),
        ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return AsyncValue.data(items);
      },
    ),
  );
});

// ---------------------------------------------------------------------------
// Workspaces
// ---------------------------------------------------------------------------

final workspacesProvider =
    StreamProvider.autoDispose<List<Workspace>>((ref) {
  return ref.watch(sdkProvider).watchWorkspaces();
});

final workspaceProvider = StreamProvider.autoDispose
    .family<Workspace?, String>((ref, id) {
  return ref.watch(sdkProvider).watchWorkspace(id: id);
});

/// Reads and parses dspatch.workspace.yml from a workspace's project directory.
/// Returns null if the file is missing or invalid.
final workspaceConfigProvider = FutureProvider.autoDispose
    .family<WorkspaceConfig?, String>((ref, projectPath) async {
  try {
    final sdk = ref.watch(sdkProvider);
    final file = await _readFileAsString('$projectPath/dspatch.workspace.yml');
    if (file == null) return null;
    return await sdk.parseWorkspaceConfig(yaml: file);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Workspace Runs
// ---------------------------------------------------------------------------

/// Watches all runs for a workspace, ordered by startedAt DESC.
final workspaceRunsProvider = StreamProvider.autoDispose
    .family<List<WorkspaceRun>, String>((ref, workspaceId) {
  return ref.watch(sdkProvider).watchWorkspaceRuns(workspaceId: workspaceId);
});

/// Derives the active run (status == 'starting' or 'running') from the runs stream.
final activeRunProvider = Provider.autoDispose
    .family<WorkspaceRun?, String>((ref, workspaceId) {
  final runs = ref.watch(workspaceRunsProvider(workspaceId)).valueOrNull ?? [];
  for (final run in runs) {
    if (run.status == 'starting' || run.status == 'running') return run;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Workspace Agents
// ---------------------------------------------------------------------------

/// Reactive stream of workspace agents for a given run.
final workspaceAgentsProvider = StreamProvider.autoDispose
    .family<List<WorkspaceAgent>, String>((ref, runId) {
  return ref.watch(sdkProvider).watchWorkspaceAgents(runId: runId);
});

// ---------------------------------------------------------------------------
// Agent selection state
// ---------------------------------------------------------------------------

/// Which instance is currently selected in the workspace view sidebar.
/// `null` = workspace-level view (Logs/Usage/Inquiries/Info tabs).
/// Value is an instanceId (String).
final selectedInstanceProvider = StateProvider.autoDispose
    .family<String?, String>(
  (ref, workspaceId) => null,
);

// ---------------------------------------------------------------------------
// Per-agent data streams
// ---------------------------------------------------------------------------

/// Watches messages for a specific agent instance within a run.
final agentMessagesProvider = StreamProvider.autoDispose.family<
    List<AgentMessage>,
    ({String runId, String instanceId})>(
  (ref, p) => ref
      .watch(sdkProvider)
      .watchAgentMessages(runId: p.runId, instanceId: p.instanceId),
);

/// Watches activity events for a specific agent instance.
final agentActivityProvider = StreamProvider.autoDispose.family<
    List<AgentActivity>,
    ({String runId, String instanceId})>(
  (ref, p) => ref
      .watch(sdkProvider)
      .watchAgentActivity(runId: p.runId, instanceId: p.instanceId),
);

/// Watches logs for a run, optionally filtered by instanceId.
final workspaceLogsProvider = StreamProvider.autoDispose.family<
    List<AgentLog>,
    ({String runId, String? instanceId})>(
  (ref, p) => ref.watch(sdkProvider).watchAgentLogs(
      runId: p.runId,
      instanceId: p.instanceId),
);

/// Watches usage for a run, optionally filtered by instanceId.
final workspaceUsageProvider = StreamProvider.autoDispose.family<
    List<AgentUsage>,
    ({String runId, String? instanceId})>(
  (ref, p) => ref.watch(sdkProvider).watchAgentUsage(
      runId: p.runId,
      instanceId: p.instanceId),
);

// ---------------------------------------------------------------------------
// Inquiries
// ---------------------------------------------------------------------------

/// Watches all inquiries for a workspace run.
final workspaceInquiriesProvider = StreamProvider.autoDispose
    .family<List<WorkspaceInquiry>, String>(
  (ref, runId) => ref
      .watch(sdkProvider)
      .watchWorkspaceInquiries(runId: runId),
);

/// Watches a single workspace inquiry by ID.
/// Emits `null` when the inquiry doesn't exist (e.g. workspace was deleted).
final workspaceInquiryProvider = StreamProvider.autoDispose
    .family<WorkspaceInquiry?, String>(
  (ref, id) =>
      ref.watch(sdkProvider).watchWorkspaceInquiry(id: id),
);

/// Watches pending workspace inquiry count for badges.
final pendingWorkspaceInquiryCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, runId) => ref
      .watch(sdkProvider)
      .watchWorkspaceInquiries(runId: runId)
      .map((list) =>
          list.where((i) => i.status == InquiryStatus.pending).length),
);

/// Watches inquiries from the latest run of each workspace (for global inquiry list).
final allInquiriesProvider =
    StreamProvider.autoDispose<List<InquiryWithWorkspace>>((ref) {
  return ref.watch(sdkProvider).watchAllInquiries();
});

/// Global pending inquiry count across all workspaces (for sidebar badge).
final globalPendingInquiryCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  return ref.watch(sdkProvider).watchPendingInquiryCount();
});

// ---------------------------------------------------------------------------
// Docker
// ---------------------------------------------------------------------------

/// Docker daemon status. Auto-disposed when Engine screen is not active.
/// Refresh via `ref.invalidate(dockerStatusProvider)`.
final dockerStatusProvider = FutureProvider.autoDispose<DockerStatus>((ref) {
  return ref.watch(sdkProvider).detectDockerStatus();
});

/// Polls d:spatch containers every 3 seconds. Auto-disposed when the
/// Engine screen unmounts — no polling overhead when not viewing containers.
final containerListProvider =
    StreamProvider.autoDispose<List<ContainerSummary>>((ref) async* {
  final sdk = ref.watch(sdkProvider);
  while (true) {
    try {
      yield await sdk.listContainers();
    } catch (e) {
      debugPrint('[docker] Container poll failed: $e');
      rethrow;
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// ---------------------------------------------------------------------------
// API Keys
// ---------------------------------------------------------------------------

/// Reactive stream of all API keys. Auto-disposes when no listeners remain.
final apiKeysProvider =
    StreamProvider.autoDispose<List<ApiKey>>((ref) {
  return ref.watch(sdkProvider).watchApiKeys();
});

// ---------------------------------------------------------------------------
// Hub
// ---------------------------------------------------------------------------

/// Checks for agent template updates from the hub (triggered on demand).
final hubAgentUpdatesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(sdkProvider).checkForAgentUpdates();
});

/// Checks for workspace template updates from the hub (triggered on demand).
final hubWorkspaceUpdatesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(sdkProvider).checkForWorkspaceUpdates();
});

// ---------------------------------------------------------------------------
// UI State
// ---------------------------------------------------------------------------

/// Search query for workspace list filtering.
final workspaceSearchQueryProvider = StateProvider<String>((_) => '');

/// Active container filter for the Engine screen's container table.
enum ContainerFilter { all, running, stopped }

final containerFilterProvider =
    StateProvider<ContainerFilter>((_) => ContainerFilter.all);

/// Ephemeral log lines displayed in the operation console.
final operationLogsProvider = StateProvider<List<String>>((_) => []);

/// Whether a Docker operation (build, bulk action) is currently running.
final operationInProgressProvider = StateProvider<bool>((_) => false);

/// Current theme mode, loaded from preferences at startup. Defaults to [ThemeMode.system].
final themeModeProvider = StateProvider<ThemeMode>(
  (_) => ThemeMode.system,
);

/// Database health status from startup check. Null means healthy (no warning needed).
/// Set in main.dart only when status is [repaired] or [reset].
final dbHealthStatusProvider = StateProvider<String?>((_) => null);

/// Ephemeral cache for backup codes returned by confirm2fa.
/// Set by AuthController.confirm2fa, consumed by BackupCodesScreen,
/// cleared after acknowledgement.
final pendingBackupCodesProvider = StateProvider<List<String>?>((_) => null);

// ---------------------------------------------------------------------------
// Database State
// ---------------------------------------------------------------------------

/// Watches the Rust SDK's database state (Ready / Closed / MigrationPending).
/// Used by the router to refresh when the DB becomes ready after setup,
/// and by the setup screen to detect pending migrations.
final databaseStateStreamProvider = StreamProvider<DatabaseReadyState>((ref) {
  return ref.watch(sdkProvider).watchDatabaseState();
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Reads a file as a UTF-8 string, returning null if the file doesn't exist.
Future<String?> _readFileAsString(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsString();
}
