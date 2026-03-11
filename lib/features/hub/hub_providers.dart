// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';

// ---------------------------------------------------------------------------
// Agent browsing state
// ---------------------------------------------------------------------------

final hubAgentSearchProvider = StateProvider.autoDispose<String>((_) => '');
final hubAgentCategoryProvider =
    StateProvider.autoDispose<String?>((_) => null);
final hubAgentCursorProvider =
    StateProvider.autoDispose<String?>((_) => null);

final hubAgentsProvider =
    FutureProvider.autoDispose<(List<HubAgentSummary>, HubPagination)>((ref) {
  final sdk = ref.watch(sdkProvider);
  final search = ref.watch(hubAgentSearchProvider);
  final category = ref.watch(hubAgentCategoryProvider);
  final cursor = ref.watch(hubAgentCursorProvider);
  return sdk.hubBrowseAgents(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  );
});

final hubAgentCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) {
  return ref.watch(sdkProvider).hubAgentCategories();
});

// ---------------------------------------------------------------------------
// Workspace browsing state
// ---------------------------------------------------------------------------

final hubWorkspaceSearchProvider =
    StateProvider.autoDispose<String>((_) => '');
final hubWorkspaceCategoryProvider =
    StateProvider.autoDispose<String?>((_) => null);
final hubWorkspaceCursorProvider =
    StateProvider.autoDispose<String?>((_) => null);

final hubWorkspacesProvider = FutureProvider.autoDispose<
    (List<HubWorkspaceSummary>, HubPagination)>((ref) {
  final sdk = ref.watch(sdkProvider);
  final search = ref.watch(hubWorkspaceSearchProvider);
  final category = ref.watch(hubWorkspaceCategoryProvider);
  final cursor = ref.watch(hubWorkspaceCursorProvider);
  return sdk.hubBrowseWorkspaces(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  );
});

final hubWorkspaceCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) {
  return ref.watch(sdkProvider).hubWorkspaceCategories();
});

// ---------------------------------------------------------------------------
// Inline hub strip (independent from dialog browsing state)
// ---------------------------------------------------------------------------

final hubStripAgentsProvider =
    FutureProvider<List<HubAgentSummary>>((ref) async {
  final sdk = ref.watch(sdkProvider);
  final (agents, _) = await sdk.hubBrowseAgents(perPage: 8);
  return agents;
});

final hubStripWorkspacesProvider =
    FutureProvider<List<HubWorkspaceSummary>>((ref) async {
  final sdk = ref.watch(sdkProvider);
  final (workspaces, _) = await sdk.hubBrowseWorkspaces(perPage: 8);
  return workspaces;
});

// ---------------------------------------------------------------------------
// Unified search (dropdown on list screens)
// ---------------------------------------------------------------------------

/// Search query for workspace unified search dropdown.
final workspaceUnifiedSearchProvider =
    StateProvider.autoDispose<String>((_) => '');

/// Hub workspace results for the unified search dropdown.
final hubWorkspaceSearchResultsProvider =
    FutureProvider.autoDispose<List<HubWorkspaceSummary>>((ref) async {
  final query = ref.watch(workspaceUnifiedSearchProvider);
  if (query.isEmpty) return [];
  final sdk = ref.watch(sdkProvider);
  final (results, _) = await sdk.hubBrowseWorkspaces(search: query, perPage: 5);
  return results;
});

/// Search query for agent template unified search dropdown.
final agentProviderUnifiedSearchProvider =
    StateProvider.autoDispose<String>((_) => '');

/// Hub agent results for the unified search dropdown.
final hubAgentSearchResultsProvider =
    FutureProvider.autoDispose<List<HubAgentSummary>>((ref) async {
  final query = ref.watch(agentProviderUnifiedSearchProvider);
  if (query.isEmpty) return [];
  final sdk = ref.watch(sdkProvider);
  final (results, _) = await sdk.hubBrowseAgents(search: query, perPage: 5);
  return results;
});

// ---------------------------------------------------------------------------
// Vote state
// ---------------------------------------------------------------------------

/// Set of slugs the current user has liked (agents).
final likedAgentSlugsProvider = StateProvider<Set<String>>((_) => {});

/// Set of slugs the current user has liked (workspaces).
final likedWorkspaceSlugsProvider = StateProvider<Set<String>>((_) => {});

/// Load user's votes on app startup (called when auth state changes to connected).
final loadUserVotesProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState == null || authState.mode != AuthMode.connected) return;

  final sdk = ref.watch(sdkProvider);
  try {
    final agentSlugs = await sdk.hubMyVotes(targetType: 'agent');
    final workspaceSlugs = await sdk.hubMyVotes(targetType: 'workspace');
    ref.read(likedAgentSlugsProvider.notifier).state = agentSlugs.toSet();
    ref.read(likedWorkspaceSlugsProvider.notifier).state =
        workspaceSlugs.toSet();
  } catch (_) {
    // Non-critical, fail silently
  }
});
