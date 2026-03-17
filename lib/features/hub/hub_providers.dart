// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/commands/hub.dart';
import '../../models/hub_types.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_token.dart';

// ---------------------------------------------------------------------------
// Agent browsing state
// ---------------------------------------------------------------------------

final hubAgentSearchProvider = StateProvider.autoDispose<String>((_) => '');
final hubAgentCategoryProvider =
    StateProvider.autoDispose<String?>((_) => null);
final hubAgentCursorProvider =
    StateProvider.autoDispose<String?>((_) => null);

final hubAgentsProvider =
    FutureProvider.autoDispose<(List<HubAgentSummary>, HubPagination)>((ref) async {
  final client = ref.watch(engineClientProvider);
  final search = ref.watch(hubAgentSearchProvider);
  final category = ref.watch(hubAgentCategoryProvider);
  final cursor = ref.watch(hubAgentCursorProvider);
  final result = await client.send(HubBrowseAgents(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  ));
  return (result.data, result.pagination);
});

final hubAgentCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubAgentCategories());
  return result.data;
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
    (List<HubWorkspaceSummary>, HubPagination)>((ref) async {
  final client = ref.watch(engineClientProvider);
  final search = ref.watch(hubWorkspaceSearchProvider);
  final category = ref.watch(hubWorkspaceCategoryProvider);
  final cursor = ref.watch(hubWorkspaceCursorProvider);
  final result = await client.send(HubBrowseWorkspaces(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  ));
  return (result.data, result.pagination);
});

final hubWorkspaceCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubWorkspaceCategories());
  return result.data;
});

// ---------------------------------------------------------------------------
// Inline hub strip (independent from dialog browsing state)
// ---------------------------------------------------------------------------

final hubStripAgentsProvider =
    FutureProvider<List<HubAgentSummary>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubBrowseAgents(perPage: 8));
  return result.data;
});

final hubStripWorkspacesProvider =
    FutureProvider<List<HubWorkspaceSummary>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubBrowseWorkspaces(perPage: 8));
  return result.data;
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
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubBrowseWorkspaces(search: query, perPage: 5));
  return result.data;
});

/// Search query for agent template unified search dropdown.
final agentProviderUnifiedSearchProvider =
    StateProvider.autoDispose<String>((_) => '');

/// Hub agent results for the unified search dropdown.
final hubAgentSearchResultsProvider =
    FutureProvider.autoDispose<List<HubAgentSummary>>((ref) async {
  final query = ref.watch(agentProviderUnifiedSearchProvider);
  if (query.isEmpty) return [];
  final client = ref.watch(engineClientProvider);
  final result = await client.send(HubBrowseAgents(search: query, perPage: 5));
  return result.data;
});

// ---------------------------------------------------------------------------
// Like state
// ---------------------------------------------------------------------------

/// Set of slugs the current user has liked (agents).
final likedAgentSlugsProvider = StateProvider<Set<String>>((_) => {});

/// Set of slugs the current user has liked (workspaces).
final likedWorkspaceSlugsProvider = StateProvider<Set<String>>((_) => {});

/// Load user's likes on app startup (called when auth state changes to connected).
final loadUserVotesProvider = FutureProvider.autoDispose<void>((ref) async {
  final authToken = ref.watch(authTokenProvider);
  if (authToken is! BackendToken) return;

  final client = ref.watch(engineClientProvider);
  try {
    final agentResult = await client.send(HubMyVotes(itemType: 'agent'));
    final workspaceResult = await client.send(HubMyVotes(itemType: 'workspace'));
    final agentSlugs = ((agentResult.raw['slugs'] as List<dynamic>?) ?? []).cast<String>();
    final workspaceSlugs = ((workspaceResult.raw['slugs'] as List<dynamic>?) ?? []).cast<String>();
    ref.read(likedAgentSlugsProvider.notifier).state = agentSlugs.toSet();
    ref.read(likedWorkspaceSlugsProvider.notifier).state =
        workspaceSlugs.toSet();
  } catch (_) {
    // Non-critical, fail silently
  }
});
