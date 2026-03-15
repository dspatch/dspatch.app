// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/engine_database.dart';
import '../engine_client/backend_auth.dart';
import '../engine_client/engine_auth.dart';
import '../engine_client/engine_client.dart';
import '../engine_client/engine_connection.dart';
import '../engine_client/models/auth_phase.dart';
import '../engine_client/models/auth_state.dart';
import '../engine_client/models/auth_token.dart';
import '../engine_client/models/backend_auth_state.dart';
import '../engine_client/models/db_state.dart';
import '../engine_client/secure_token_store.dart';
import '../engine_client/protocol/protocol.dart';
import '../features/agent_providers/models/agent_list_item.dart';
import '../models/commands/commands.dart';
import '../models/docker_types.dart';

// ---------------------------------------------------------------------------
// Engine Database (read-only Drift)
// ---------------------------------------------------------------------------

/// The read-only Drift database backed by the engine's SQLite file.
///
/// Initialized with a placeholder in main.dart. SetupScreen swaps it to
/// the real database after fetching the path from `/engine-info`.
final engineDatabaseProvider = StateProvider<EngineDatabase>(
  (_) => throw UnimplementedError('Override engineDatabaseProvider in main.dart'),
);

// ---------------------------------------------------------------------------
// Engine Client (WebSocket command API)
// ---------------------------------------------------------------------------

/// The Engine Client for sending commands to the engine over WebSocket.
/// Must be overridden in main.dart with the connected instance from EngineBootstrap.
///
/// Example:
/// ```dart
/// engineClientProvider.overrideWithValue(bootstrapResult.client)
/// ```
final engineClientProvider = Provider<EngineClient>(
  (_) => throw UnimplementedError('Override engineClientProvider in main.dart'),
);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

/// Auth state comes from the engine over WebSocket events, not from the DB.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(engineClientProvider);
  return client.events
      .where((e) => e.name == 'auth_state_changed')
      .map((e) => AuthState.fromJson(e.data));
});

/// Current auth mode for UI decisions (anonymous vs connected).
final authModeProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.mode ??
      AuthMode.undetermined;
});

/// EngineAuth for connect/refresh calls to the engine.
/// Overridden in main.dart with the instance from EngineBootstrap.
final engineAuthProvider = Provider<EngineAuth>(
  (_) => throw UnimplementedError('Override engineAuthProvider in main.dart'),
);

/// EngineConnection for reconnect support.
/// Overridden in main.dart with the instance from EngineBootstrap.
final engineConnectionProvider = Provider<EngineConnection>(
  (_) => throw UnimplementedError('Override engineConnectionProvider in main.dart'),
);

/// BackendAuth client for direct backend communication.
/// Overridden in main.dart with the configured instance.
final backendAuthProvider = Provider<BackendAuth>(
  (_) => throw UnimplementedError('Override backendAuthProvider in main.dart'),
);

/// Tracks the backend auth state during the multi-step login/register flow.
/// Local to the app — not from the engine.
final backendAuthStateProvider = StateProvider<BackendAuthState?>((_) => null);

/// Secure token store for persisting auth credentials in the OS keyring.
/// Overridden in main.dart.
final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (_) => throw UnimplementedError('Override secureTokenStoreProvider in main.dart'),
);

/// Single source of truth for routing. AuthController is the only writer.
final authPhaseProvider = StateProvider<AuthPhase>((_) => AuthPhase.unauthenticated);

/// Credentials for API calls and persistence. Not used for routing.
final authTokenProvider = StateProvider<AuthToken?>((_) => null);

/// Engine database state. Written by WS event listener, read by setup screen.
/// StateProvider (not stream) so the value is never missed.
final dbStateProvider = StateProvider<DbState>((_) => DbState.unknown);

/// Whether the engine WebSocket is currently connected. Informational only —
/// does not affect routing. Can drive a connectivity indicator in the UI.
final engineSessionProvider = StateProvider<bool>((_) => false);

// ---------------------------------------------------------------------------
// Engine Events
// ---------------------------------------------------------------------------

/// Real-time engine ephemeral events (replaces sdkEventsProvider).
final engineEventsProvider = StreamProvider<EventFrame>((ref) {
  return ref.watch(engineClientProvider).events;
});

// ---------------------------------------------------------------------------
// Agent Providers (the entity, not Riverpod providers)
// ---------------------------------------------------------------------------

final agentProvidersProvider =
    StreamProvider.autoDispose<List<AgentProvider>>((ref) {
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.agentProviders)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

final agentProviderProvider = StreamProvider.autoDispose
    .family<AgentProvider?, String>((ref, id) {
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.agentProviders)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
});

// ---------------------------------------------------------------------------
// Agent Templates
// ---------------------------------------------------------------------------

final agentTemplatesProvider =
    StreamProvider.autoDispose<List<AgentTemplate>>((ref) {
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.agentTemplates)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

final agentTemplateProvider = StreamProvider.autoDispose
    .family<AgentTemplate?, String>((ref, id) {
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.agentTemplates)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
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
        final items = <AgentListItem>[
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
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.workspaces)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

final workspaceProvider = StreamProvider.autoDispose
    .family<Workspace?, String>((ref, id) {
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.workspaces)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
});

/// Reads and parses dspatch.workspace.yml from a workspace's project directory.
/// Returns null if the file is missing or invalid.
final workspaceConfigProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, projectPath) async {
  try {
    final file = await _readFileAsString('$projectPath/dspatch.workspace.yml');
    if (file == null) return null;
    final result = await ref.read(engineClientProvider)
        .sendCommand('parse_workspace_config', {'yaml': file});
    return result;
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
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.workspaceRuns)
        ..where((t) => t.workspaceId.equals(workspaceId))
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
      .watch();
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
  final db = ref.watch(engineDatabaseProvider);
  return (db.select(db.workspaceAgents)
        ..where((t) => t.runId.equals(runId)))
      .watch();
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
  (ref, p) {
    final db = ref.watch(engineDatabaseProvider);
    return (db.select(db.agentMessages)
          ..where((t) =>
              t.runId.equals(p.runId) & t.instanceId.equals(p.instanceId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  },
);

/// Watches activity events for a specific agent instance.
final agentActivityProvider = StreamProvider.autoDispose.family<
    List<AgentActivityEvent>,
    ({String runId, String instanceId})>(
  (ref, p) {
    final db = ref.watch(engineDatabaseProvider);
    return (db.select(db.agentActivityEvents)
          ..where((t) =>
              t.runId.equals(p.runId) & t.instanceId.equals(p.instanceId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  },
);

/// Watches logs for a run, optionally filtered by instanceId.
final workspaceLogsProvider = StreamProvider.autoDispose.family<
    List<AgentLog>,
    ({String runId, String? instanceId})>(
  (ref, p) {
    final db = ref.watch(engineDatabaseProvider);
    var query = db.select(db.agentLogs)
      ..where((t) => t.runId.equals(p.runId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    if (p.instanceId != null) {
      query = query..where((t) => t.instanceId.equals(p.instanceId!));
    }
    return query.watch();
  },
);

/// Watches usage for a run, optionally filtered by instanceId.
final workspaceUsageProvider = StreamProvider.autoDispose.family<
    List<AgentUsageRecord>,
    ({String runId, String? instanceId})>(
  (ref, p) {
    final db = ref.watch(engineDatabaseProvider);
    var query = db.select(db.agentUsageRecords)
      ..where((t) => t.runId.equals(p.runId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    if (p.instanceId != null) {
      query = query..where((t) => t.instanceId.equals(p.instanceId!));
    }
    return query.watch();
  },
);

// ---------------------------------------------------------------------------
// Inquiries
// ---------------------------------------------------------------------------

/// Watches all inquiries for a workspace run.
final workspaceInquiriesProvider = StreamProvider.autoDispose
    .family<List<WorkspaceInquiry>, String>(
  (ref, runId) {
    final db = ref.watch(engineDatabaseProvider);
    return (db.select(db.workspaceInquiries)
          ..where((t) => t.runId.equals(runId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  },
);

/// Watches a single workspace inquiry by ID.
final workspaceInquiryProvider = StreamProvider.autoDispose
    .family<WorkspaceInquiry?, String>(
  (ref, id) {
    final db = ref.watch(engineDatabaseProvider);
    return (db.select(db.workspaceInquiries)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  },
);

/// Watches pending workspace inquiry count for badges.
final pendingWorkspaceInquiryCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, runId) {
    final db = ref.watch(engineDatabaseProvider);
    return (db.select(db.workspaceInquiries)
          ..where(
              (t) => t.runId.equals(runId) & t.status.equals('pending')))
        .watch()
        .map((list) => list.length);
  },
);

/// Watches inquiries from the latest run of each workspace (for global inquiry list).
final allInquiriesProvider =
    StreamProvider.autoDispose<List<WorkspaceInquiry>>((ref) {
  final db = ref.watch(engineDatabaseProvider);
  return db.customSelect(
    '''
    SELECT wi.* FROM workspace_inquiries wi
    INNER JOIN (
      SELECT wr.id as run_id FROM workspace_runs wr
      INNER JOIN (
        SELECT workspace_id, MAX(started_at) as max_started
        FROM workspace_runs GROUP BY workspace_id
      ) latest ON wr.workspace_id = latest.workspace_id
        AND wr.started_at = latest.max_started
    ) lr ON wi.run_id = lr.run_id
    ORDER BY wi.created_at DESC
    ''',
    readsFrom: {db.workspaceInquiries, db.workspaceRuns},
  ).watch().map((rows) => rows.map((row) {
        return db.workspaceInquiries.map(row.data);
      }).toList());
});

/// Global pending inquiry count across all workspaces (for sidebar badge).
final globalPendingInquiryCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(engineDatabaseProvider);
  return db.customSelect(
    '''
    SELECT COUNT(*) as c FROM workspace_inquiries wi
    INNER JOIN (
      SELECT wr.id as run_id FROM workspace_runs wr
      INNER JOIN (
        SELECT workspace_id, MAX(started_at) as max_started
        FROM workspace_runs GROUP BY workspace_id
      ) latest ON wr.workspace_id = latest.workspace_id
        AND wr.started_at = latest.max_started
    ) lr ON wi.run_id = lr.run_id
    WHERE wi.status = 'pending'
    ''',
    readsFrom: {db.workspaceInquiries, db.workspaceRuns},
  ).watchSingle().map((row) => row.read<int>('c'));
});

// ---------------------------------------------------------------------------
// Docker
// ---------------------------------------------------------------------------

/// Docker daemon status. Auto-disposed when Engine screen is not active.
/// Refresh via `ref.invalidate(dockerStatusProvider)`.
final dockerStatusProvider = FutureProvider.autoDispose<DockerStatus>((ref) {
  return ref.watch(engineClientProvider).send(DetectDockerStatus());
});

/// Polls d:spatch containers every 3 seconds. Auto-disposed when the
/// Engine screen unmounts — no polling overhead when not viewing containers.
final containerListProvider =
    StreamProvider.autoDispose<List<ContainerSummary>>((ref) async* {
  final client = ref.watch(engineClientProvider);
  while (true) {
    try {
      final response = await client.send(ListContainers());
      yield response.containers;
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
  final db = ref.watch(engineDatabaseProvider);
  return db.select(db.apiKeys).watch();
});

// ---------------------------------------------------------------------------
// Hub
// ---------------------------------------------------------------------------

/// Checks for agent template updates from the hub (triggered on demand).
final hubAgentUpdatesProvider =
    FutureProvider.autoDispose<VoidResponse>((ref) async {
  return ref.watch(engineClientProvider).send(CheckForAgentUpdates());
});

/// Checks for workspace template updates from the hub (triggered on demand).
final hubWorkspaceUpdatesProvider =
    FutureProvider.autoDispose<VoidResponse>((ref) async {
  return ref.watch(engineClientProvider).send(CheckForWorkspaceUpdates());
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

/// Whether the Drift database has been opened at the correct path.
///
/// Set to `true` by [SetupScreen] after fetching the DB path from
/// `/engine-info` and swapping the [engineDatabaseProvider]. The router
/// uses this to prevent navigation to data screens before the database
/// is ready.
final databaseReadyProvider = StateProvider<bool>((_) => false);

/// Database health status from startup check. Null means healthy (no warning needed).
/// Set in main.dart only when status is [repaired] or [reset].
final dbHealthStatusProvider = StateProvider<String?>((_) => null);

/// Set to true during logout to prevent the router from treating stale
/// engine auth state (cached by StreamProvider) as a valid session.
/// Cleared when the user logs in again or enters anonymous mode.
final loggedOutProvider = StateProvider<bool>((_) => false);

/// Ephemeral cache for backup codes returned by confirm2fa.
/// Set by AuthController.confirm2fa, consumed by BackupCodesScreen,
/// cleared after acknowledgement.
final pendingBackupCodesProvider = StateProvider<List<String>?>((_) => null);

// ---------------------------------------------------------------------------
// Database State
// ---------------------------------------------------------------------------

/// Database state is managed by the engine. Listens to engine events.
final databaseStateStreamProvider = StreamProvider<String>((ref) {
  final client = ref.watch(engineClientProvider);
  return client.events
      .where((e) => e.name == 'database_state_changed')
      .map((e) => e.data['state'] as String);
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
