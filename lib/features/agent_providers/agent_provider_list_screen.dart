// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';

import '../../core/extensions/drift_extensions.dart';
import '../../database/engine_database.dart';
import '../../models/hub_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/agent_source_scanner.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/display_error.dart';
import '../../di/providers.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/unified_search_bar.dart';
import '../hub/hub_agent_browser.dart';
import '../hub/hub_providers.dart';
import '../hub/hub_clone_template_dialog.dart';
import '../hub/hub_submit_agent_dialog.dart';
import '../hub/hub_submit_template_dialog.dart';
import '../hub/widgets/hub_hero_banner.dart';
import '../hub/widgets/hub_strip.dart';
import '../hub/widgets/hub_strip_card.dart';
import 'agent_provider_controller.dart';
import 'models/agent_list_item.dart';
import 'widgets/agent_provider_card.dart';
import 'widgets/agent_provider_list_skeleton.dart';
import 'widgets/create_template_dialog.dart';

class AgentProviderListScreen extends ConsumerStatefulWidget {
  const AgentProviderListScreen({super.key});

  @override
  ConsumerState<AgentProviderListScreen> createState() =>
      _AgentProviderListScreenState();
}

class _AgentProviderListScreenState
    extends ConsumerState<AgentProviderListScreen> {
  String _searchQuery = '';
  int _displayCount = 5;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(agentListItemsProvider);
    final hubStripAsync = ref.watch(hubStripAgentsProvider);
    final hubSearchAsync = ref.watch(hubAgentSearchResultsProvider);

    return SingleChildScrollView(
      child: ContentArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + add buttons
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Button(
                  label: 'Add Provider',
                  icon: LucideIcons.plus,
                  onPressed: () => context.go('/agent-providers/new'),
                ),
                const SizedBox(width: Spacing.sm),
                Button(
                  label: 'New Template',
                  icon: LucideIcons.file_plus,
                  variant: ButtonVariant.outline,
                  onPressed: () => _showCreateTemplateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Unified Search
            UnifiedSearchBar(
              placeholder: 'Search agents and hub...',
              onQueryChanged: (q) {
                setState(() => _searchQuery = q);
                ref
                    .read(agentProviderUnifiedSearchProvider.notifier)
                    .state = q;
              },
              localResults: _buildLocalSearchResults(itemsAsync),
              hubResults: _buildHubSearchResults(hubSearchAsync),
              isLoadingHub: hubSearchAsync.isLoading,
            ),
            const SizedBox(height: Spacing.xl),

            // Getting started banner (below search, above local section)
            if ((itemsAsync.valueOrNull?.length ?? 0) < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: GettingStartedBanner(
                  steps: [
                    GettingStartedStep(
                      number: 1,
                      title: 'Add a provider',
                      description:
                          'Define an agent with its entry point and environment.',
                      actionLabel: 'Create',
                      onAction: () => context.go('/agent-providers/new'),
                    ),
                    GettingStartedStep(
                      number: 2,
                      title: 'Browse the community hub',
                      description:
                          'Find pre-built agents shared by the community.',
                      actionLabel: 'Browse',
                      onAction: () => _openHubBrowser(context),
                    ),
                    const GettingStartedStep(
                      number: 3,
                      title: 'Use in a workspace',
                      description:
                          'Reference your providers in a workspace config to orchestrate agents.',
                    ),
                  ],
                ),
              ),

            // Local Section
            itemsAsync.when(
              loading: () => const AgentProviderListSkeleton(),
              error: (e, _) => ErrorStateView(
                message: 'Failed to load agents: ${displayError(e)}',
                onRetry: () {
                  ref.invalidate(agentProvidersProvider);
                  ref.invalidate(agentTemplatesProvider);
                },
              ),
              data: (items) => _buildLocalSection(items),
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
      AsyncValue<List<AgentListItem>> itemsAsync) {
    final items = itemsAsync.valueOrNull;
    if (items == null || _searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return items
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            (item.description?.toLowerCase().contains(q) ?? false) ||
            (item.provider?.entryPoint.toLowerCase().contains(q) ?? false) ||
            (item.template?.sourceUri.toLowerCase().contains(q) ?? false))
        .take(5)
        .map((item) => SearchResultItem(
              title: item.name,
              subtitle: item.isTemplate
                  ? item.template!.sourceUri
                  : (item.description ?? item.provider!.entryPoint),
              onTap: () {
                if (item.isTemplate) {
                  context.go('/agent-providers/templates/${item.id}/edit');
                } else if (item.provider!.isHub) {
                  _showHubDetail(context, item.provider!);
                } else {
                  context.go('/agent-providers/${item.id}/edit');
                }
              },
            ))
        .toList();
  }

  List<SearchResultItem> _buildHubSearchResults(
      AsyncValue<List<HubAgentSummary>> hubSearchAsync) {
    final results = hubSearchAsync.valueOrNull;
    if (results == null) return [];
    return results
        .map((agent) => SearchResultItem(
              title: agent.name,
              isHub: true,
              hubAuthor: agent.author,
              hubLikes: agent.likes,
              hubVerified: agent.verified,
              onTap: () => _openHubBrowser(context),
              onDownload: () => _openHubBrowser(context),
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Local section
  // ---------------------------------------------------------------------------

  Widget _buildLocalSection(List<AgentListItem> items) {
    final displayItems = items.take(_displayCount).toList();
    final hasMore = items.length > _displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Text(
          'Installed',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Template cards
        ...displayItems.map((item) {
          final isHub = !item.isTemplate && item.provider!.isHub;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: AgentProviderCard(
              item: item,
              onTap: item.isTemplate
                  ? () => context.go('/agent-providers/templates/${item.id}/edit')
                  : isHub
                      ? () => _showHubDetail(context, item.provider!)
                      : () => context.go('/agent-providers/${item.id}/edit'),
              onDelete: () => _confirmDelete(context, ref, item),
              onSubmitToHub: isHub
                  ? null
                  : item.isTemplate
                      ? () => _submitTemplateToHub(context, item.template!)
                      : () => _submitToHub(context, item.provider!),
              onClone: isHub ? () => _cloneTemplate(context, item.provider!) : null,
            ),
          );
        }),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Community Hub grid
  // ---------------------------------------------------------------------------

  Widget _buildHubGrid(AsyncValue<List<HubAgentSummary>> hubStripAsync) {
    return hubStripAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: Spinner(size: SpinnerSize.sm, color: AppColors.mutedForeground),
        ),
      ),
      error: (e, _) => ErrorStateView(
        message: 'Could not load community hub agents.',
        onRetry: () => ref.invalidate(hubStripAgentsProvider),
      ),
      data: (hubAgents) => HubTileGrid<HubAgentSummary>(
        items: hubAgents,
        onBrowseAll: () => _openHubBrowser(context),
        onRefresh: () => ref.invalidate(hubStripAgentsProvider),
        tileBuilder: (agent) => HubTile(
          name: agent.name,
          author: agent.author,
          description: agent.description,
          slug: agent.slug,
          targetType: 'agent',
          likes: agent.likes,
          userLiked: agent.userLiked,
          downloads: agent.downloads,
          verified: agent.verified,
          category: agent.category,
          onTap: () => _openHubBrowser(context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _openHubBrowser(BuildContext context) {
    DspatchDialog.show(
      context: context,
      maxWidth: 720,
      builder: (_) => const HubAgentBrowserDialog(),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    DspatchDialog.show(
      context: context,
      maxWidth: 480,
      builder: (_) => const CreateTemplateDialog(),
    );
  }

  Future<void> _submitTemplateToHub(
      BuildContext context, AgentTemplate template) async {
    if (!await requireAuth(context, ref)) return;
    if (!context.mounted) return;

    // Only templates backed by hub providers can be submitted.
    if (!template.sourceUri.startsWith('dspatch://agent/')) {
      toast('Only templates backed by hub providers can be submitted',
          type: ToastType.error);
      return;
    }

    DspatchDialog.show(
      context: context,
      maxWidth: 560,
      builder: (_) => HubSubmitTemplateDialog(template: template),
    );
  }

  Future<void> _submitToHub(BuildContext context, AgentProvider template) async {
    if (!await requireAuth(context, ref)) return;

    // For local templates, run pre-flight git checks before opening dialog.
    if (template.isLocal) {
      final sourcePath = template.sourcePath;
      if (sourcePath == null || sourcePath.isEmpty) {
        toast('No source path configured', type: ToastType.error);
        return;
      }

      final remoteUrl = await AgentSourceScanner.getGitRemoteUrl(sourcePath);
      if (remoteUrl == null) {
        toast(
          'No git remote origin found',
          description: 'Configure a remote origin to submit to the hub.',
          type: ToastType.error,
        );
        return;
      }

      final (branch, hasUncommitted) = await (
        AgentSourceScanner.getGitBranch(sourcePath),
        AgentSourceScanner.hasUncommittedChanges(sourcePath),
      ).wait;
      final hasUnpushed = branch != null
          ? await AgentSourceScanner.hasUnpushedCommits(sourcePath, branch)
          : false;

      if (!context.mounted) return;

      DspatchDialog.show(
        context: context,
        maxWidth: 560,
        builder: (_) => HubSubmitAgentDialog(
          template: template,
          detectedRemoteUrl: AgentSourceScanner.sshToHttpsUrl(remoteUrl),
          detectedBranch: branch,
          hasUncommittedChanges: hasUncommitted,
          hasUnpushedCommits: hasUnpushed,
        ),
      );
    } else {
      DspatchDialog.show(
        context: context,
        maxWidth: 560,
        builder: (_) => HubSubmitAgentDialog(template: template),
      );
    }
  }

  void _cloneTemplate(BuildContext context, AgentProvider template) {
    DspatchDialog.show(
      context: context,
      maxWidth: 520,
      builder: (_) => HubCloneTemplateDialog(template: template),
    );
  }

  void _showHubDetail(BuildContext context, AgentProvider t) {
    DspatchDialog.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogHeader(children: [
            DialogTitle(text: t.name),
            if (t.description != null && t.description!.isNotEmpty)
              DialogDescription(text: t.description!),
          ]),
          DialogContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hubDetailRow('Author', t.hubAuthor ?? 'Unknown'),
                _hubDetailRow('Category', t.hubCategory ?? 'None'),
                _hubDetailRow('Version', 'v${t.hubVersion ?? 0}'),
                _hubDetailRow('Entry Point', t.entryPoint),
                if (t.hubRepoUrl != null)
                  _hubDetailRow('Repository', t.hubRepoUrl!),
                if (t.hubTags.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: t.hubTags
                        .map((tag) => DspatchBadge(
                              label: tag,
                              variant: BadgeVariant.outline,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          DialogFooter(children: [
            Button(
              label: 'Close',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            Button(
              label: 'Clone',
              icon: LucideIcons.copy,
              onPressed: () {
                Navigator.of(ctx).pop();
                _cloneTemplate(context, t);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _hubDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AgentListItem item,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: item.isTemplate ? 'Delete Template' : 'Delete Provider',
      description:
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
    );
    if (confirmed) {
      if (item.isTemplate) {
        ref
            .read(agentProviderControllerProvider.notifier)
            .deleteAgentTemplate(item.id);
      } else {
        ref
            .read(agentProviderControllerProvider.notifier)
            .deleteAgentProvider(item.id);
      }
    }
  }
}
