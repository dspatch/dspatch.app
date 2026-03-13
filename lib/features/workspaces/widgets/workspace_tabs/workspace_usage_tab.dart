// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_engine/dspatch_engine.dart';
import 'dart:math' as math;

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/providers.dart';

/// Workspace-level usage dashboard with per-agent cost breakdown.
class WorkspaceUsageTab extends ConsumerWidget {
  const WorkspaceUsageTab({
    super.key,
    required this.runId,
    required this.agents,
  });

  final String runId;
  final List<WorkspaceAgent> agents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(workspaceUsageProvider((
      runId: runId,
      instanceId: null,
    )));

    return usageAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.chart_column,
            title: 'No Usage Data',
            description:
                'Token usage will appear as agents make LLM calls.',
          );
        }

        final totalInput =
            records.fold<int>(0, (s, r) => s + r.inputTokens);
        final totalOutput =
            records.fold<int>(0, (s, r) => s + r.outputTokens);
        final totalCost =
            records.fold<double>(0, (s, r) => s + r.costUsd);

        // Group by agent
        final byAgent = <String, List<AgentUsage>>{};
        for (final r in records) {
          byAgent.putIfAbsent(r.agentKey, () => []).add(r);
        }
        final agentCosts = byAgent.entries
            .map((e) => (
                  key: e.key,
                  cost: e.value.fold<double>(0, (s, r) => s + r.costUsd),
                  tokens: e.value.fold<int>(
                      0, (s, r) => s + r.inputTokens + r.outputTokens),
                  calls: e.value.length,
                ))
            .toList()
          ..sort((a, b) => b.cost.compareTo(a.cost));

        final maxAgentCost = agentCosts.isEmpty
            ? 0.0
            : agentCosts.first.cost;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(Spacing.md),
          child: ContentArea(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Stat cards ──
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.tag,
                      value: _fmt(totalInput + totalOutput),
                      label: 'Tokens',
                      sub: '${_fmt(totalInput)} in / ${_fmt(totalOutput)} out',
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.dollar_sign,
                      value: '\$${totalCost.toStringAsFixed(4)}',
                      label: 'Cost',
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.cpu,
                      value: '${records.length}',
                      label: 'LLM Calls',
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.users,
                      value: '${byAgent.length}',
                      label: 'Agents',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),

              // ── Per-agent cost breakdown ──
              if (agentCosts.length > 1) ...[
                DspatchCard(
                  title: 'Cost by Agent',
                  child: Column(
                    children: [
                      for (final agent in agentCosts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      agent.key,
                                      style: const TextStyle(
                                        color: AppColors.foreground,
                                        fontSize: 12,
                                        fontFamily: AppFonts.mono,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${agent.cost.toStringAsFixed(4)} '
                                    '(${_fmt(agent.tokens)} tokens, '
                                    '${agent.calls} calls)',
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.xs),
                              Progress(
                                value: maxAgentCost > 0
                                    ? agent.cost / maxAgentCost
                                    : 0,
                                height: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],

              // ── Per-call breakdown table ──
              DspatchCard(
                title: 'Per-Call Breakdown',
                padding: const EdgeInsets.all(Spacing.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    dataTextStyle: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 12,
                      fontFamily: AppFonts.mono,
                    ),
                    columnSpacing: Spacing.lg,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Agent')),
                      DataColumn(label: Text('Model')),
                      DataColumn(label: Text('Input'), numeric: true),
                      DataColumn(label: Text('Output'), numeric: true),
                      DataColumn(label: Text('Cache R'), numeric: true),
                      DataColumn(label: Text('Cache W'), numeric: true),
                      DataColumn(label: Text('Cost'), numeric: true),
                    ],
                    rows: [
                      for (var i = 0; i < math.min(records.length, 100); i++)
                        DataRow(cells: [
                          DataCell(Text('${i + 1}')),
                          DataCell(
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 80),
                              child: Text(
                                records[i].agentKey,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 120),
                              child: Text(
                                records[i].model,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(_fmt(records[i].inputTokens))),
                          DataCell(Text(_fmt(records[i].outputTokens))),
                          DataCell(Text(_fmt(records[i].cacheReadTokens))),
                          DataCell(Text(_fmt(records[i].cacheWriteTokens))),
                          DataCell(Text(
                              '\$${records[i].costUsd.toStringAsFixed(4)}')),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
      loading: () => const Center(child: Spinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.sub,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFonts.mono,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
