// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for Hub API operations.
///
/// Bug fixes applied:
/// - `hub_resolve_agent`: uses `agent_id` (not `slug`)
/// - `hub_my_votes`: uses `item_type` (not `target_type`)
/// - `hub_vote_agent`: uses `agent_id` + `vote: int` (not `slug` + `like: bool`)
/// - `hub_vote_workspace`: uses `workspace_id` + `vote: int` (not `slug` + `like: bool`)
library;

import '../hub_types.dart';
import 'command.dart';

// ── Response types ─────────────────────────────────────────────────────────

class HubBrowseAgentsResponse extends EngineResponse {
  const HubBrowseAgentsResponse({required this.data, required this.pagination});
  final List<HubAgentSummary> data;
  final HubPagination pagination;

  factory HubBrowseAgentsResponse.fromJson(Map<String, dynamic> json) {
    return HubBrowseAgentsResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => HubAgentSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: HubPagination.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class HubBrowseWorkspacesResponse extends EngineResponse {
  const HubBrowseWorkspacesResponse(
      {required this.data, required this.pagination});
  final List<HubWorkspaceSummary> data;
  final HubPagination pagination;

  factory HubBrowseWorkspacesResponse.fromJson(Map<String, dynamic> json) {
    return HubBrowseWorkspacesResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  HubWorkspaceSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: HubPagination.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class HubCategoriesResponse extends EngineResponse {
  const HubCategoriesResponse({required this.data});
  final List<HubCategoryCount> data;

  factory HubCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return HubCategoriesResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map(
                  (e) => HubCategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HubResolveAgentResponse extends EngineResponse {
  const HubResolveAgentResponse({required this.raw});
  final Map<String, dynamic> raw;

  factory HubResolveAgentResponse.fromJson(Map<String, dynamic> json) {
    return HubResolveAgentResponse(raw: json);
  }
}

class HubResolveWorkspaceResponse extends EngineResponse {
  const HubResolveWorkspaceResponse({required this.raw});
  final Map<String, dynamic> raw;

  factory HubResolveWorkspaceResponse.fromJson(Map<String, dynamic> json) {
    return HubResolveWorkspaceResponse(raw: json);
  }
}

class HubMyVotesResponse extends EngineResponse {
  const HubMyVotesResponse({required this.raw});
  final Map<String, dynamic> raw;

  factory HubMyVotesResponse.fromJson(Map<String, dynamic> json) {
    return HubMyVotesResponse(raw: json);
  }
}

class HubTagsResponse extends EngineResponse {
  const HubTagsResponse({required this.tags});
  final List<HubTagRef> tags;

  factory HubTagsResponse.fromJson(Map<String, dynamic> json) {
    return HubTagsResponse(
      tags: (json['data'] as List<dynamic>?)
              ?.map((e) => HubTagRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ── Commands ───────────────────────────────────────────────────────────────

class HubBrowseAgents extends EngineCommand<HubBrowseAgentsResponse> {
  HubBrowseAgents({this.search, this.category, this.cursor, this.perPage});
  final String? search;
  final String? category;
  final String? cursor;
  final int? perPage;

  @override
  String get method => 'hub_browse_agents';

  @override
  Map<String, dynamic> get params => {
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (cursor != null) 'cursor': cursor,
        if (perPage != null) 'per_page': perPage,
      };

  @override
  HubBrowseAgentsResponse parseResponse(Map<String, dynamic> result) =>
      HubBrowseAgentsResponse.fromJson(result);
}

class HubBrowseWorkspaces extends EngineCommand<HubBrowseWorkspacesResponse> {
  HubBrowseWorkspaces({this.search, this.category, this.cursor, this.perPage});
  final String? search;
  final String? category;
  final String? cursor;
  final int? perPage;

  @override
  String get method => 'hub_browse_workspaces';

  @override
  Map<String, dynamic> get params => {
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (cursor != null) 'cursor': cursor,
        if (perPage != null) 'per_page': perPage,
      };

  @override
  HubBrowseWorkspacesResponse parseResponse(Map<String, dynamic> result) =>
      HubBrowseWorkspacesResponse.fromJson(result);
}

class HubAgentCategories extends EngineCommand<HubCategoriesResponse> {
  @override
  String get method => 'hub_agent_categories';

  @override
  Map<String, dynamic>? get params => null;

  @override
  HubCategoriesResponse parseResponse(Map<String, dynamic> result) =>
      HubCategoriesResponse.fromJson(result);
}

class HubWorkspaceCategories extends EngineCommand<HubCategoriesResponse> {
  @override
  String get method => 'hub_workspace_categories';

  @override
  Map<String, dynamic>? get params => null;

  @override
  HubCategoriesResponse parseResponse(Map<String, dynamic> result) =>
      HubCategoriesResponse.fromJson(result);
}

/// Bug fix: Rust expects `agent_id`, not `slug`.
class HubResolveAgent extends EngineCommand<HubResolveAgentResponse> {
  HubResolveAgent({required this.agentId});
  final String agentId;

  @override
  String get method => 'hub_resolve_agent';

  @override
  Map<String, dynamic> get params => {'agent_id': agentId};

  @override
  HubResolveAgentResponse parseResponse(Map<String, dynamic> result) =>
      HubResolveAgentResponse.fromJson(result);
}

class HubResolveWorkspace extends EngineCommand<HubResolveWorkspaceResponse> {
  HubResolveWorkspace({required this.workspaceId});
  final String workspaceId;

  @override
  String get method => 'hub_resolve_workspace';

  @override
  Map<String, dynamic> get params => {'workspace_id': workspaceId};

  @override
  HubResolveWorkspaceResponse parseResponse(Map<String, dynamic> result) =>
      HubResolveWorkspaceResponse.fromJson(result);
}

class HubResolveWorkspaceDetails
    extends EngineCommand<HubResolveWorkspaceResponse> {
  HubResolveWorkspaceDetails({required this.slug});
  final String slug;

  @override
  String get method => 'hub_resolve_workspace_details';

  @override
  Map<String, dynamic> get params => {'slug': slug};

  @override
  HubResolveWorkspaceResponse parseResponse(Map<String, dynamic> result) =>
      HubResolveWorkspaceResponse.fromJson(result);
}

class HubSubmitAgent extends VoidEngineCommand {
  HubSubmitAgent({
    required this.name,
    required this.repoUrl,
    this.branch,
    this.description,
    this.category,
    this.tags,
    this.entryPoint,
    this.sdkVersion,
  });

  final String name;
  final String repoUrl;
  final String? branch;
  final String? description;
  final String? category;
  final List<Map<String, dynamic>>? tags;
  final String? entryPoint;
  final String? sdkVersion;

  @override
  String get method => 'hub_submit_agent';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'repo_url': repoUrl,
        if (branch != null) 'branch': branch,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
        if (entryPoint != null) 'entry_point': entryPoint,
        if (sdkVersion != null) 'sdk_version': sdkVersion,
      };
}

class HubSubmitTemplate extends VoidEngineCommand {
  HubSubmitTemplate({
    required this.name,
    required this.configYaml,
    required this.sourceUri,
    this.description,
    this.category,
    this.tags,
  });

  final String name;
  final String configYaml;
  final String sourceUri;
  final String? description;
  final String? category;
  final List<Map<String, dynamic>>? tags;

  @override
  String get method => 'hub_submit_template';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'config_yaml': configYaml,
        'source_uri': sourceUri,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
      };
}

class HubSubmitWorkspace extends VoidEngineCommand {
  HubSubmitWorkspace({
    required this.name,
    required this.configJson,
    this.description,
    this.category,
    this.tags,
  });

  final String name;
  final String configJson;
  final String? description;
  final String? category;
  final List<Map<String, dynamic>>? tags;

  @override
  String get method => 'hub_submit_workspace';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'config_json': configJson,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
      };
}

class HubVoteAgent extends VoidEngineCommand {
  HubVoteAgent({required this.author, required this.slug, required this.vote});
  final String author;
  final String slug;
  final int vote;

  @override
  String get method => 'hub_vote_agent';

  @override
  Map<String, dynamic> get params => {
        'author': author,
        'slug': slug,
        'vote': vote,
      };
}

/// Bug fix: Rust expects `workspace_id` + `vote: i32`, not `slug` + `like: bool`.
class HubVoteWorkspace extends VoidEngineCommand {
  HubVoteWorkspace({required this.workspaceId, required this.vote});
  final String workspaceId;
  final int vote;

  @override
  String get method => 'hub_vote_workspace';

  @override
  Map<String, dynamic> get params =>
      {'workspace_id': workspaceId, 'vote': vote};
}

/// Bug fix: Rust expects `item_type`, not `target_type`.
class HubMyVotes extends EngineCommand<HubMyVotesResponse> {
  HubMyVotes({required this.itemType});
  final String itemType;

  @override
  String get method => 'hub_my_votes';

  @override
  Map<String, dynamic> get params => {'item_type': itemType};

  @override
  HubMyVotesResponse parseResponse(Map<String, dynamic> result) =>
      HubMyVotesResponse.fromJson(result);
}

class HubSearchTags extends EngineCommand<HubTagsResponse> {
  HubSearchTags({required this.query, this.category});
  final String query;
  final String? category;

  @override
  String get method => 'hub_search_tags';

  @override
  Map<String, dynamic> get params => {
        'query': query,
        if (category != null) 'category': category,
      };

  @override
  HubTagsResponse parseResponse(Map<String, dynamic> result) =>
      HubTagsResponse.fromJson(result);
}

class HubPopularTags extends EngineCommand<HubTagsResponse> {
  HubPopularTags({this.category});
  final String? category;

  @override
  String get method => 'hub_popular_tags';

  @override
  Map<String, dynamic> get params => {
        if (category != null) 'category': category,
      };

  @override
  HubTagsResponse parseResponse(Map<String, dynamic> result) =>
      HubTagsResponse.fromJson(result);
}

class CheckForAgentUpdates extends VoidEngineCommand {
  @override
  String get method => 'check_for_agent_updates';

  @override
  Map<String, dynamic>? get params => null;
}

class CheckForWorkspaceUpdates extends VoidEngineCommand {
  @override
  String get method => 'check_for_workspace_updates';

  @override
  Map<String, dynamic>? get params => null;
}

// ── Git preflight ────────────────────────────────────────────────────────

/// Response from the engine's `git_preflight_check` command.
class GitPreflightResult extends EngineResponse {
  const GitPreflightResult({
    required this.isRepo,
    this.remoteUrl,
    this.branch,
    required this.hasUncommittedChanges,
    required this.hasUnpushedCommits,
  });

  final bool isRepo;
  final String? remoteUrl;
  final String? branch;
  final bool hasUncommittedChanges;
  final bool hasUnpushedCommits;

  factory GitPreflightResult.fromJson(Map<String, dynamic> json) {
    return GitPreflightResult(
      isRepo: json['is_repo'] as bool? ?? false,
      remoteUrl: json['remote_url'] as String?,
      branch: json['branch'] as String?,
      hasUncommittedChanges: json['has_uncommitted_changes'] as bool? ?? false,
      hasUnpushedCommits: json['has_unpushed_commits'] as bool? ?? false,
    );
  }
}

class GitPreflightCheck extends EngineCommand<GitPreflightResult> {
  GitPreflightCheck({required this.directory});
  final String directory;

  @override
  String get method => 'git_preflight_check';

  @override
  Map<String, dynamic> get params => {'directory': directory};

  @override
  GitPreflightResult parseResponse(Map<String, dynamic> result) =>
      GitPreflightResult.fromJson(result);
}
