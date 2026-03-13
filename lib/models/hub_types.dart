// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Hub API response types for browsing agents and workspaces.

class HubAgentSummary {
  const HubAgentSummary({
    required this.slug,
    required this.name,
    this.author,
    this.description,
    this.category,
    required this.tags,
    required this.stars,
    required this.downloads,
    required this.version,
    required this.verified,
    required this.userLiked,
    this.agentType,
    this.sourceSlug,
  });

  final String slug;
  final String name;
  final String? author;
  final String? description;
  final String? category;
  final List<HubTagRef> tags;
  final int stars;
  final int downloads;
  final int version;
  final bool verified;
  final bool userLiked;
  final String? agentType;
  final String? sourceSlug;

  factory HubAgentSummary.fromJson(Map<String, dynamic> json) {
    return HubAgentSummary(
      slug: json['slug'] as String,
      name: json['name'] as String,
      author: json['author'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => HubTagRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stars: json['stars'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      verified: json['verified'] as bool? ?? false,
      userLiked: json['user_liked'] as bool? ?? false,
      agentType: json['agent_type'] as String?,
      sourceSlug: json['source_slug'] as String?,
    );
  }
}

class HubWorkspaceSummary {
  const HubWorkspaceSummary({
    required this.slug,
    required this.name,
    this.author,
    this.description,
    this.category,
    required this.tags,
    required this.stars,
    required this.downloads,
    required this.version,
    required this.verified,
    required this.userLiked,
    required this.agentCount,
  });

  final String slug;
  final String name;
  final String? author;
  final String? description;
  final String? category;
  final List<HubTagRef> tags;
  final int stars;
  final int downloads;
  final int version;
  final bool verified;
  final bool userLiked;
  final int agentCount;

  factory HubWorkspaceSummary.fromJson(Map<String, dynamic> json) {
    return HubWorkspaceSummary(
      slug: json['slug'] as String,
      name: json['name'] as String,
      author: json['author'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => HubTagRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stars: json['stars'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      verified: json['verified'] as bool? ?? false,
      userLiked: json['user_liked'] as bool? ?? false,
      agentCount: json['agent_count'] as int? ?? 0,
    );
  }
}

class HubCategoryCount {
  const HubCategoryCount({
    this.category,
    required this.count,
  });

  final String? category;
  final int count;

  factory HubCategoryCount.fromJson(Map<String, dynamic> json) {
    return HubCategoryCount(
      category: json['category'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

class HubPagination {
  const HubPagination({
    this.nextCursor,
    required this.hasMore,
  });

  final String? nextCursor;
  final bool hasMore;

  factory HubPagination.fromJson(Map<String, dynamic> json) {
    return HubPagination(
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

class HubTagRef {
  const HubTagRef({
    required this.slug,
    required this.displayName,
    required this.category,
  });

  final String slug;
  final String displayName;
  final String category;

  factory HubTagRef.fromJson(Map<String, dynamic> json) {
    return HubTagRef(
      slug: json['slug'] as String,
      displayName: json['display_name'] as String? ?? json['slug'] as String,
      category: json['category'] as String? ?? 'general',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HubTagRef &&
          runtimeType == other.runtimeType &&
          slug == other.slug;

  @override
  int get hashCode => slug.hashCode;
}
