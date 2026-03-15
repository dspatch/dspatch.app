// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../models/commands/config.dart';
import '../../models/commands/hub.dart';
import '../../models/commands/settings.dart';
import '../../models/commands/workspace.dart';
import '../../models/hub_types.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'hub_providers.dart';
import 'widgets/hub_like_button.dart';

/// Dialog for browsing and downloading community hub workspaces.
///
/// Downloading a workspace resolves its agent references, creates local
/// hub-sourced agent templates for each, and shows a success message.
class HubWorkspaceBrowserDialog extends ConsumerStatefulWidget {
  const HubWorkspaceBrowserDialog({super.key});

  @override
  ConsumerState<HubWorkspaceBrowserDialog> createState() =>
      _HubWorkspaceBrowserDialogState();
}

class _HubWorkspaceBrowserDialogState
    extends ConsumerState<HubWorkspaceBrowserDialog> {
  final _searchController = TextEditingController();
  final _allWorkspaces = <HubWorkspaceSummary>[];
  String? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  String _downloadingSlug = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadWorkspace(HubWorkspaceSummary workspace) async {
    setState(() => _downloadingSlug = workspace.slug);
    try {
      final client = ref.read(engineClientProvider);
      final details =
          await client.send(HubResolveWorkspaceDetails(slug: workspace.slug));
      final configYamlString = details.raw['config_yaml'] as String? ?? '';
      final agentRefs = ((details.raw['agent_refs'] as List<dynamic>?) ?? []).cast<String>();
      final version = details.raw['version'] as int? ?? 0;

      // Create agent templates for each referenced agent that doesn't exist yet.
      // agentRefs are full URIs like "dspatch://agent/<author>/<slug>".
      // Extract "author/slug" for the resolve call.
      int addedCount = 0;
      for (final agentRef in agentRefs) {
        try {
          final uri = Uri.tryParse(agentRef);
          final authorSlug = uri != null
              ? uri.pathSegments.skip(1).join('/')
              : agentRef;
          final resolved = await client.send(HubResolveAgent(agentId: authorSlug));
          await client.send(CreateAgentProvider(request: {
            'name': agentRef,
            'source_type': 'hub',
            'hub_slug': agentRef,
            'hub_tags': const [],
            'hub_version': resolved.raw['version'],
            'hub_repo_url': resolved.raw['repo_url'],
            'hub_commit_hash': resolved.raw['commit_hash'],
            'entry_point': resolved.raw['entry_point'] ?? '',
            'git_url': resolved.raw['repo_url'],
            'git_branch': resolved.raw['branch'],
            'required_env': const [],
            'required_mounts': const [],
            'fields': const {},
          }));
          addedCount++;
        } catch (e) {
          debugPrint('Failed to create template for agent ref: $e');
        }
      }

      // Create the local workspace from the resolved config YAML.
      final parsedConfig =
          await client.send(ParseWorkspaceConfig(yaml: configYamlString));
      final projectPath = parsedConfig.config.workspaceDir ?? '';
      await client.send(CreateWorkspace(
        projectPath: projectPath,
        configYaml: configYamlString,
      ));

      if (mounted) {
        final wsName = parsedConfig.config.name;
        final agentMsg = addedCount > 0
            ? ' with $addedCount agent template${addedCount == 1 ? '' : 's'}'
            : '';
        toast(
          'Workspace "$wsName" v$version imported$agentMsg',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        toast('Failed to download workspace: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _downloadingSlug = '');
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final client = ref.read(engineClientProvider);
      final search = ref.read(hubWorkspaceSearchProvider);
      final category = ref.read(hubWorkspaceCategoryProvider);
      final result = await client.send(HubBrowseWorkspaces(
        search: search.isEmpty ? null : search,
        category: category,
        cursor: _nextCursor,
        perPage: 20,
      ));
      if (mounted) {
        setState(() {
          _allWorkspaces.addAll(result.data);
          _nextCursor = result.pagination.nextCursor;
          _hasMore = result.pagination.hasMore;
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
    final workspacesAsync = ref.watch(hubWorkspacesProvider);
    final categoriesAsync = ref.watch(hubWorkspaceCategoriesProvider);
    final selectedCategory = ref.watch(hubWorkspaceCategoryProvider);

    return SizedBox(
        height: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            DialogHeader(children: [
              const DialogTitle(text: 'Browse Community Workspaces'),
              const DialogDescription(
                text:
                    'Discover workspace configurations shared by the community.',
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
                    placeholder: 'Search workspaces...',
                    prefix: const Icon(LucideIcons.search,
                        size: 14, color: AppColors.mutedForeground),
                    onChanged: (value) {
                      ref
                          .read(hubWorkspaceSearchProvider.notifier)
                          .state = value;
                      _allWorkspaces.clear();
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  categoriesAsync.when(
                    data: (categories) => _CategoryChips(
                      categories: categories,
                      selected: selectedCategory,
                      onSelected: (cat) {
                        ref
                            .read(
                                hubWorkspaceCategoryProvider.notifier)
                            .state = cat;
                        _allWorkspaces.clear();
                      },
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // ── Workspace List ──
            Expanded(
              child: workspacesAsync.when(
                loading: () => const Center(
                  child: Spinner(
                    size: SpinnerSize.sm,
                    color: AppColors.mutedForeground,
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  child: ErrorStateView(
                    message: 'Failed to load workspaces: $e',
                    onRetry: () =>
                        ref.invalidate(hubWorkspacesProvider),
                  ),
                ),
                data: (result) {
                  final (freshWorkspaces, pagination) = result;

                  if (_allWorkspaces.isEmpty &&
                      freshWorkspaces.isNotEmpty) {
                    _allWorkspaces.addAll(freshWorkspaces);
                    _nextCursor = pagination.nextCursor;
                    _hasMore = pagination.hasMore;
                  }

                  if (_allWorkspaces.isEmpty) {
                    return const Center(
                      child: Text(
                        'No workspaces found.',
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
                    itemCount:
                        _allWorkspaces.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      if (index == _allWorkspaces.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: Spacing.sm),
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
                      final ws = _allWorkspaces[index];
                      return _HubWorkspaceCard(
                        workspace: ws,
                        isDownloading:
                            _downloadingSlug == ws.slug,
                        onDownload: () => _downloadWorkspace(ws),
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

class _HubWorkspaceCard extends StatelessWidget {
  const _HubWorkspaceCard({
    required this.workspace,
    required this.isDownloading,
    required this.onDownload,
  });

  final HubWorkspaceSummary workspace;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: name, author, tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        workspace.name,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (workspace.verified) ...[
                      const SizedBox(width: Spacing.xs),
                      const Icon(LucideIcons.badge_check,
                          size: 14, color: AppColors.primary),
                    ],
                    if (workspace.category != null) ...[
                      const SizedBox(width: Spacing.sm),
                      DspatchBadge(
                        label: workspace.category!,
                        variant: BadgeVariant.secondary,
                      ),
                    ],
                    ...workspace.tags.take(3).map((tag) => Padding(
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
                    if (workspace.tags.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: Spacing.xs),
                        child: Text(
                          '+${workspace.tags.length - 3}',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                if (workspace.author != null)
                  Text(
                    'by ${workspace.author}',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Right: agent count, stars, version, action
          const SizedBox(width: Spacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.bot,
                  size: 13, color: AppColors.mutedForeground),
              const SizedBox(width: 2),
              Text(
                '${workspace.agentCount}',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontFamily: AppFonts.mono,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              HubLikeButton(
                slug: workspace.slug,
                targetType: 'workspace',
                initialStars: workspace.stars,
                initialLiked: workspace.userLiked,
              ),
              const SizedBox(width: Spacing.sm),
              const Icon(Icons.download_outlined,
                  size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 2),
              Text(
                '${workspace.downloads}',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'v${workspace.version}',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontFamily: AppFonts.mono,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Button(
                label: 'Download',
                icon: LucideIcons.download,
                size: ButtonSize.sm,
                loading: isDownloading,
                onPressed: onDownload,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
