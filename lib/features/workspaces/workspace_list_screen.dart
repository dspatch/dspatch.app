// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import '../../database/engine_database.dart';
import '../../models/hub_types.dart';

import 'package:dspatch_ui/dspatch_ui.dart';

import '../../core/utils/display_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaml/yaml.dart';

import '../../core/utils/auth_gate.dart';
import '../../di/providers.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/unified_search_bar.dart';
import '../hub/hub_providers.dart';
import '../hub/hub_submit_workspace_dialog.dart';
import '../hub/hub_workspace_browser.dart';
import '../hub/widgets/hub_hero_banner.dart';
import '../hub/widgets/hub_strip.dart';
import '../hub/widgets/hub_strip_card.dart';
import 'workspace_controller.dart';
import 'widgets/workspace_card.dart';
import 'widgets/workspace_list_empty.dart';
import 'widgets/workspace_list_skeleton.dart';

class WorkspaceListScreen extends ConsumerStatefulWidget {
  const WorkspaceListScreen({super.key});

  @override
  ConsumerState<WorkspaceListScreen> createState() =>
      _WorkspaceListScreenState();
}

class _WorkspaceListScreenState extends ConsumerState<WorkspaceListScreen> {
  String _searchQuery = '';
  int _displayCount = 5;

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final hubStripAsync = ref.watch(hubStripWorkspacesProvider);
    final hubSearchAsync = ref.watch(hubWorkspaceSearchResultsProvider);

    return SingleChildScrollView(
      child: ContentArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + create button
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Workspaces',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Button(
                  label: 'Create Workspace',
                  icon: LucideIcons.plus,
                  onPressed: () => context.go('/workspaces/new'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Unified Search Bar
            UnifiedSearchBar(
              placeholder: 'Search workspaces and hub...',
              onQueryChanged: (q) {
                setState(() => _searchQuery = q);
                ref.read(workspaceUnifiedSearchProvider.notifier).state = q;
              },
              localResults: _buildLocalSearchResults(workspacesAsync),
              hubResults: _buildHubSearchResults(hubSearchAsync),
              isLoadingHub: hubSearchAsync.isLoading,
            ),
            const SizedBox(height: Spacing.xl),

            // Getting started banner (below search, above local section)
            if ((workspacesAsync.valueOrNull?.length ?? 0) < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: GettingStartedBanner(
                  steps: [
                    GettingStartedStep(
                      number: 1,
                      title: 'Create an agent template',
                      description:
                          'Define an agent with its entry point and configuration.',
                      actionLabel: 'Create',
                      onAction: () => context.go('/agent-providers/new'),
                    ),
                    GettingStartedStep(
                      number: 2,
                      title: 'Create a workspace',
                      description:
                          'Compose agents into a workspace with a dspatch.workspace.yml config.',
                      actionLabel: 'Create',
                      onAction: () => context.go('/workspaces/new'),
                    ),
                    const GettingStartedStep(
                      number: 3,
                      title: 'Launch your workspace',
                      description:
                          'Hit the play button to spin up your agents in Docker.',
                    ),
                  ],
                ),
              ),

            // Local Section
            workspacesAsync.when(
              loading: () => const WorkspaceListSkeleton(),
              error: (e, _) => ErrorStateView(
                message: 'Failed to load workspaces: ${displayError(e)}',
                onRetry: () => ref.invalidate(workspacesProvider),
              ),
              data: (workspaces) =>
                  _buildLocalSection(workspaces),
            ),

            const SizedBox(height: Spacing.xxl),

            // Community Hub Grid
            _buildHubGrid(hubStripAsync),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search result builders
  // ---------------------------------------------------------------------------

  List<SearchResultItem> _buildLocalSearchResults(
      AsyncValue<List<Workspace>> workspacesAsync) {
    final workspaces = workspacesAsync.valueOrNull;
    if (workspaces == null || _searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return workspaces
        .where((w) =>
            w.name.toLowerCase().contains(q) ||
            w.projectPath.toLowerCase().contains(q))
        .take(5)
        .map((w) => SearchResultItem(
              title: w.name,
              subtitle: w.projectPath,
              onTap: () => context.go('/workspaces/${w.id}'),
            ))
        .toList();
  }

  List<SearchResultItem> _buildHubSearchResults(
      AsyncValue<List<HubWorkspaceSummary>> hubSearchAsync) {
    final results = hubSearchAsync.valueOrNull;
    if (results == null) return [];
    return results
        .map((ws) => SearchResultItem(
              title: ws.name,
              isHub: true,
              hubAuthor: ws.author,
              hubStars: ws.stars,
              hubVerified: ws.verified,
              onTap: () => _openHubBrowser(context),
              onDownload: () => _openHubBrowser(context),
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Local section
  // ---------------------------------------------------------------------------

  Widget _buildLocalSection(List<Workspace> workspaces) {
    final filtered = workspaces;
    final displayItems = filtered.take(_displayCount).toList();
    final hasMore = filtered.length > _displayCount;
    final controllerState = ref.watch(workspaceControllerProvider);
    final isLoading = controllerState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Row(
          children: [
            Text(
              'Local',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // Workspace cards
        if (filtered.isEmpty)
          const WorkspaceListEmpty()
        else ...[
          ...displayItems.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: WorkspaceCard(
                  workspace: w,
                  isLoading: isLoading,
                  onTap: () => context.go('/workspaces/${w.id}'),
                  onDelete: () => _confirmDelete(w),
                  onSubmitToHub: () => _submitToHub(context, ref, w),
                  onStart: () => ref
                      .read(workspaceControllerProvider.notifier)
                      .launchWorkspace(w.id),
                  onStop: () => ref
                      .read(workspaceControllerProvider.notifier)
                      .stopWorkspace(w.id),
                ),
              )),
          if (hasMore)
            Center(
              child: Button(
                label: 'Show More',
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                onPressed: () => setState(() => _displayCount += 5),
              ),
            ),
        ],

      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hub grid
  // ---------------------------------------------------------------------------

  Widget _buildHubGrid(AsyncValue<List<HubWorkspaceSummary>> hubStripAsync) {
    return hubStripAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: Spinner(size: SpinnerSize.sm, color: AppColors.mutedForeground),
        ),
      ),
      error: (e, _) => ErrorStateView(
        message: 'Could not load community hub workspaces.',
        onRetry: () => ref.invalidate(hubStripWorkspacesProvider),
      ),
      data: (hubWorkspaces) => HubTileGrid<HubWorkspaceSummary>(
        items: hubWorkspaces,
        onBrowseAll: () => _openHubBrowser(context),
        onRefresh: () => ref.invalidate(hubStripWorkspacesProvider),
        tileBuilder: (ws) => HubTile(
          name: ws.name,
          author: ws.author,
          description: ws.description,
          slug: ws.slug,
          targetType: 'workspace',
          stars: ws.stars,
          userLiked: ws.userLiked,
          downloads: ws.downloads,
          verified: ws.verified,
          category: ws.category,
          onTap: () => _openHubBrowser(context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _openHubBrowser(BuildContext context) {
    DspatchDialog.show(
      context: context,
      maxWidth: 720,
      builder: (_) => const HubWorkspaceBrowserDialog(),
    );
  }

  Future<void> _submitToHub(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
  ) async {
    if (!await requireAuth(context, ref)) return;

    final configFile = File('${workspace.projectPath}/dspatch.workspace.yml');
    if (!await configFile.exists()) {
      toast(
        'No dspatch.workspace.yml found in workspace directory',
        type: ToastType.error,
      );
      return;
    }

    final yamlContent = await configFile.readAsString();
    final dynamic raw;
    try {
      raw = loadYaml(yamlContent);
    } catch (e) {
      toast('Failed to parse workspace config: $e', type: ToastType.error);
      return;
    }
    if (raw == null) {
      toast('Workspace config is empty', type: ToastType.error);
      return;
    }

    final configYaml = _deepConvert(raw) as Map<String, dynamic>;

    if (!context.mounted) return;

    await DspatchDialog.show(
      context: context,
      maxWidth: 560,
      builder: (_) => HubSubmitWorkspaceDialog(
        name: workspace.name,
        configYaml: configYaml,
      ),
    );
  }

  /// Recursively converts [YamlMap]/[YamlList] to plain [Map]/[List].
  static dynamic _deepConvert(dynamic value) {
    if (value is YamlMap) {
      return <String, dynamic>{
        for (final e in value.entries) e.key.toString(): _deepConvert(e.value),
      };
    }
    if (value is YamlList) {
      return value.map<dynamic>(_deepConvert).toList();
    }
    return value;
  }

  Future<void> _confirmDelete(Workspace workspace) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Delete Workspace',
      description:
          'Are you sure you want to delete "${workspace.name}"? '
          'This removes the workspace record but does not delete the project directory.',
    );
    if (confirmed) {
      ref
          .read(workspaceControllerProvider.notifier)
          .deleteWorkspace(workspace.id);
    }
  }
}
