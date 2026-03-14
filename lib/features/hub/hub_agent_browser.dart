// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../models/hub_types.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'hub_providers.dart';
import 'widgets/hub_like_button.dart';

/// Dialog for browsing and adding community hub agents.
///
/// When [selectMode] is true, tapping an agent returns the [HubAgentSummary]
/// to the caller via `Navigator.pop` instead of creating a local template.
class HubAgentBrowserDialog extends ConsumerStatefulWidget {
  const HubAgentBrowserDialog({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  ConsumerState<HubAgentBrowserDialog> createState() =>
      _HubAgentBrowserDialogState();
}

class _HubAgentBrowserDialogState
    extends ConsumerState<HubAgentBrowserDialog> {
  final _searchController = TextEditingController();
  final _allAgents = <HubAgentSummary>[];
  String? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  String _addingSlug = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAgent(HubAgentSummary agent) async {
    setState(() => _addingSlug = agent.slug);
    try {
      final client = ref.read(engineClientProvider);

      if (agent.agentType == 'template') {
        // Template flow: create a local AgentTemplate with a dspatch:// URI.
        final sourceSlug = agent.sourceSlug ?? agent.slug;
        final author = agent.author ?? 'unknown';
        final sourceUri = 'dspatch://agent/$author/$sourceSlug';

        await client.createAgentTemplate(request: {
          'name': agent.name,
          'source_uri': sourceUri,
        });

        if (mounted) {
          toast('Template "${agent.name}" added', type: ToastType.success);
        }
      } else {
        // Provider flow: resolve full metadata then create a local provider.
        final author = agent.author ?? 'unknown';
        final resolved =
            await client.hubResolveAgent(slug: '$author/${agent.slug}');

        await client.createAgentProvider(request: {
          'name': agent.name,
          'source_type': 'hub',
          'hub_slug': agent.slug,
          'hub_author': agent.author,
          'hub_category': agent.category,
          'hub_tags': agent.tags.map((t) => t.displayName).toList(),
          'hub_version': resolved['version'],
          'hub_repo_url': resolved['repo_url'],
          'hub_commit_hash': resolved['commit_hash'],
          'entry_point': resolved['entry_point'] ?? '',
          'git_url': resolved['repo_url'],
          'git_branch': resolved['branch'],
          'description': agent.description,
          'required_env': const [],
          'required_mounts': const [],
          'fields': const {},
        });

        if (mounted) {
          toast('Added "${agent.name}" to templates', type: ToastType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        toast('Failed to add agent: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _addingSlug = '');
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final client = ref.read(engineClientProvider);
      final search = ref.read(hubAgentSearchProvider);
      final category = ref.read(hubAgentCategoryProvider);
      final result = await client.hubBrowseAgents(
        search: search.isEmpty ? null : search,
        category: category,
        cursor: _nextCursor,
        perPage: 20,
      );
      final agentsList = (result['agents'] as List<dynamic>?) ?? [];
      final paginationMap = (result['pagination'] as Map<String, dynamic>?) ?? {};
      final agents = agentsList.map((a) => _hubAgentFromMap(a as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _allAgents.addAll(agents);
          _nextCursor = paginationMap['next_cursor'] as String?;
          _hasMore = paginationMap['has_more'] as bool? ?? false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        toast('Failed to load more: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(hubAgentsProvider);
    final categoriesAsync = ref.watch(hubAgentCategoriesProvider);
    final selectedCategory = ref.watch(hubAgentCategoryProvider);

    return SizedBox(
        height: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            DialogHeader(children: [
              DialogTitle(
                text: widget.selectMode
                    ? 'Select Hub Agent'
                    : 'Browse Community Agents',
              ),
              const DialogDescription(
                text: 'Discover and add agents shared by the community.',
              ),
            ]),
            const SizedBox(height: Spacing.md),

            // ── Search + Categories ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Input(
                    controller: _searchController,
                    placeholder: 'Search agents...',
                    prefix: const Icon(LucideIcons.search,
                        size: 14, color: AppColors.mutedForeground),
                    onChanged: (value) {
                      ref.read(hubAgentSearchProvider.notifier).state =
                          value;
                      _allAgents.clear();
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  categoriesAsync.when(
                    data: (categories) => _CategoryChips(
                      categories: categories,
                      selected: selectedCategory,
                      onSelected: (cat) {
                        ref
                            .read(hubAgentCategoryProvider.notifier)
                            .state = cat;
                        _allAgents.clear();
                      },
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // ── Agent List ──
            Expanded(
              child: agentsAsync.when(
                loading: () => const Center(
                  child: Spinner(
                    size: SpinnerSize.sm,
                    color: AppColors.mutedForeground,
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  child: ErrorStateView(
                    message: 'Failed to load agents: $e',
                    onRetry: () => ref.invalidate(hubAgentsProvider),
                  ),
                ),
                data: (result) {
                  final (freshAgents, pagination) = result;

                  // Seed accumulated list on first load / filter change.
                  if (_allAgents.isEmpty && freshAgents.isNotEmpty) {
                    _allAgents.addAll(freshAgents);
                    _nextCursor = pagination.nextCursor;
                    _hasMore = pagination.hasMore;
                  }

                  if (_allAgents.isEmpty) {
                    return const Center(
                      child: Text(
                        'No agents found.',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xxl,
                      vertical: Spacing.sm,
                    ),
                    itemCount: _allAgents.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      if (index == _allAgents.length) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: Spacing.sm),
                            child: Button(
                              label: 'Load More',
                              variant: ButtonVariant.outline,
                              size: ButtonSize.sm,
                              loading: _loadingMore,
                              onPressed: _loadMore,
                            ),
                          ),
                        );
                      }
                      final agent = _allAgents[index];
                      return _HubAgentCard(
                        agent: agent,
                        selectMode: widget.selectMode,
                        isAdding: _addingSlug == agent.slug,
                        onAdd: () {
                          if (widget.selectMode) {
                            Navigator.of(context).pop(agent);
                          } else {
                            _addAgent(agent);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // ── Footer ──
            DialogFooter(children: [
              Button(
                label: 'Close',
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ],
        ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<HubCategoryCount> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...categories.map((c) => _chip(
                label: '${c.category ?? 'Other'} (${c.count})',
                isSelected: selected == c.category,
                onTap: () => onSelected(c.category),
              )),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.xs),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DspatchBadge(
            label: label,
            variant:
                isSelected ? BadgeVariant.primary : BadgeVariant.outline,
          ),
        ),
      ),
    );
  }
}

class _HubAgentCard extends StatelessWidget {
  const _HubAgentCard({
    required this.agent,
    required this.selectMode,
    required this.isAdding,
    required this.onAdd,
  });

  final HubAgentSummary agent;
  final bool selectMode;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: name, author, description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        agent.name,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (agent.verified) ...[
                      const SizedBox(width: Spacing.xs),
                      const Icon(LucideIcons.badge_check,
                          size: 14, color: AppColors.primary),
                    ],
                    // Tags inline after name
                    if (agent.category != null) ...[
                      const SizedBox(width: Spacing.sm),
                      DspatchBadge(
                        label: agent.category!,
                        variant: BadgeVariant.secondary,
                      ),
                    ],
                    ...agent.tags.take(3).map((tag) => Padding(
                          padding: const EdgeInsets.only(left: Spacing.xs),
                          child: DspatchBadge(
                            label: tag.displayName,
                            variant: tag.category == 'model'
                                ? BadgeVariant.secondary
                                : tag.category == 'framework'
                                    ? BadgeVariant.primary
                                    : BadgeVariant.outline,
                          ),
                        )),
                    if (agent.tags.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: Spacing.xs),
                        child: Text(
                          '+${agent.tags.length - 3}',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                if (agent.author != null)
                  Text(
                    'by ${agent.author}',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Right: stars, version, action button
          const SizedBox(width: Spacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HubLikeButton(
                slug: agent.slug,
                targetType: 'agent',
                initialStars: agent.stars,
                initialLiked: agent.userLiked,
              ),
              const SizedBox(width: Spacing.sm),
              const Icon(Icons.download_outlined,
                  size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 2),
              Text(
                '${agent.downloads}',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'v${agent.version}',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontFamily: AppFonts.mono,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Button(
                label: selectMode ? 'Select' : 'Add',
                icon: selectMode ? LucideIcons.check : LucideIcons.plus,
                size: ButtonSize.sm,
                loading: isAdding,
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
