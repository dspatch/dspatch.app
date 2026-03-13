// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_engine/dspatch_engine.dart'
    show HubAgentSummary, HubCategoryCount, HubPagination, HubTagRef, HubWorkspaceSummary;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_state.dart';

// ---------------------------------------------------------------------------
// Map → FRB type helpers
// ---------------------------------------------------------------------------

HubAgentSummary _hubAgentFromMap(Map<String, dynamic> m) {
  final tagsRaw = (m['tags'] as List<dynamic>?) ?? [];
  return HubAgentSummary(
    slug: m['slug'] as String? ?? '',
    name: m['name'] as String? ?? '',
    description: m['description'] as String?,
    author: m['author'] as String?,
    category: m['category'] as String?,
    tags: tagsRaw
        .map((t) {
          final tm = t as Map<String, dynamic>;
          return HubTagRef(
            slug: tm['slug'] as String? ?? '',
            displayName: tm['display_name'] as String? ?? '',
            category: tm['category'] as String? ?? '',
          );
        })
        .toList(),
    stars: m['stars'] as int? ?? 0,
    downloads: m['downloads'] as int? ?? 0,
    verified: m['verified'] as bool? ?? false,
    version: m['version'] as int? ?? 0,
    userLiked: m['user_liked'] as bool? ?? false,
    agentType: m['agent_type'] as String? ?? 'provider',
    sourceSlug: m['source_slug'] as String?,
  );
}

HubWorkspaceSummary _hubWorkspaceFromMap(Map<String, dynamic> m) {
  final tagsRaw = (m['tags'] as List<dynamic>?) ?? [];
  return HubWorkspaceSummary(
    slug: m['slug'] as String? ?? '',
    name: m['name'] as String? ?? '',
    description: m['description'] as String?,
    author: m['author'] as String?,
    category: m['category'] as String?,
    tags: tagsRaw
        .map((t) {
          final tm = t as Map<String, dynamic>;
          return HubTagRef(
            slug: tm['slug'] as String? ?? '',
            displayName: tm['display_name'] as String? ?? '',
            category: tm['category'] as String? ?? '',
          );
        })
        .toList(),
    stars: m['stars'] as int? ?? 0,
    downloads: m['downloads'] as int? ?? 0,
    verified: m['verified'] as bool? ?? false,
    version: m['version'] as int? ?? 0,
    userLiked: m['user_liked'] as bool? ?? false,
    agentCount: m['agent_count'] as int? ?? 0,
  );
}

HubCategoryCount _hubCategoryFromMap(Map<String, dynamic> m) {
  return HubCategoryCount(
    category: m['category'] as String?,
    count: m['count'] as int? ?? 0,
  );
}

HubPagination _hubPaginationFromMap(Map<String, dynamic> m) {
  return HubPagination(
    perPage: m['per_page'] as int? ?? 20,
    nextCursor: m['next_cursor'] as String?,
    hasMore: m['has_more'] as bool? ?? false,
  );
}

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
  final result = await client.hubBrowseAgents(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  );
  final agentsList = (result['agents'] as List<dynamic>?) ?? [];
  final paginationMap = (result['pagination'] as Map<String, dynamic>?) ?? {};
  return (
    agentsList.map((a) => _hubAgentFromMap(a as Map<String, dynamic>)).toList(),
    _hubPaginationFromMap(paginationMap),
  );
});

final hubAgentCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.hubAgentCategories();
  final categories = (result['categories'] as List<dynamic>?) ?? [];
  return categories
      .map((c) => _hubCategoryFromMap(c as Map<String, dynamic>))
      .toList();
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
  final result = await client.hubBrowseWorkspaces(
    search: search.isEmpty ? null : search,
    category: category,
    cursor: cursor,
    perPage: 20,
  );
  final wsList = (result['workspaces'] as List<dynamic>?) ?? [];
  final paginationMap = (result['pagination'] as Map<String, dynamic>?) ?? {};
  return (
    wsList.map((w) => _hubWorkspaceFromMap(w as Map<String, dynamic>)).toList(),
    _hubPaginationFromMap(paginationMap),
  );
});

final hubWorkspaceCategoriesProvider =
    FutureProvider.autoDispose<List<HubCategoryCount>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.hubWorkspaceCategories();
  final categories = (result['categories'] as List<dynamic>?) ?? [];
  return categories
      .map((c) => _hubCategoryFromMap(c as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Inline hub strip (independent from dialog browsing state)
// ---------------------------------------------------------------------------

final hubStripAgentsProvider =
    FutureProvider<List<HubAgentSummary>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.hubBrowseAgents(perPage: 8);
  final agentsList = (result['agents'] as List<dynamic>?) ?? [];
  return agentsList
      .map((a) => _hubAgentFromMap(a as Map<String, dynamic>))
      .toList();
});

final hubStripWorkspacesProvider =
    FutureProvider<List<HubWorkspaceSummary>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final result = await client.hubBrowseWorkspaces(perPage: 8);
  final wsList = (result['workspaces'] as List<dynamic>?) ?? [];
  return wsList
      .map((w) => _hubWorkspaceFromMap(w as Map<String, dynamic>))
      .toList();
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
  final result = await client.hubBrowseWorkspaces(search: query, perPage: 5);
  final wsList = (result['workspaces'] as List<dynamic>?) ?? [];
  return wsList
      .map((w) => _hubWorkspaceFromMap(w as Map<String, dynamic>))
      .toList();
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
  final result = await client.hubBrowseAgents(search: query, perPage: 5);
  final agentsList = (result['agents'] as List<dynamic>?) ?? [];
  return agentsList
      .map((a) => _hubAgentFromMap(a as Map<String, dynamic>))
      .toList();
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

  final client = ref.watch(engineClientProvider);
  try {
    final agentResult = await client.hubMyVotes(targetType: 'agent');
    final workspaceResult = await client.hubMyVotes(targetType: 'workspace');
    final agentSlugs = ((agentResult['slugs'] as List<dynamic>?) ?? []).cast<String>();
    final workspaceSlugs = ((workspaceResult['slugs'] as List<dynamic>?) ?? []).cast<String>();
    ref.read(likedAgentSlugsProvider.notifier).state = agentSlugs.toSet();
    ref.read(likedWorkspaceSlugsProvider.notifier).state =
        workspaceSlugs.toSet();
  } catch (_) {
    // Non-critical, fail silently
  }
});
