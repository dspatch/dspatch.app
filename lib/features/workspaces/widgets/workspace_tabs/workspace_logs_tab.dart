// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/datetime_ext.dart';
import '../../../../database/engine_database.dart';
import '../../../../di/providers.dart';

/// Log level string constants matching the engine's values.
abstract final class LogLevel {
  static const debug = 'debug';
  static const info = 'info';
  static const warn = 'warn';
  static const error = 'error';
  static const all = [debug, info, warn, error];
}

/// Log source string constants matching the engine's values.
abstract final class LogSource {
  static const engine = 'engine';
  static const agent = 'agent';
  static const all = [engine, agent];
}

/// Terminal-style log viewer for workspace-level logs.
///
/// Aggregates logs from all agents with an `[agentKey]` prefix.
/// Includes inline level, source, and agent filtering above the output.
class WorkspaceLogsTab extends ConsumerStatefulWidget {
  const WorkspaceLogsTab({
    super.key,
    required this.runId,
    required this.agents,
  });

  final String runId;
  final List<WorkspaceAgent> agents;

  @override
  ConsumerState<WorkspaceLogsTab> createState() => _WorkspaceLogsTabState();
}

class _WorkspaceLogsTabState extends ConsumerState<WorkspaceLogsTab> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 50;
    if (_autoScroll != atBottom) {
      setState(() => _autoScroll = atBottom);
    }
    // Load more logs when scrolling near the top (older entries).
    if (pos.pixels < 100) {
      final current = ref.read(logPageLimitProvider);
      ref.read(logPageLimitProvider.notifier).state = current + 200;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  static String _levelTag(String level) => switch (level) {
        LogLevel.debug => 'DBG',
        LogLevel.info => 'INF',
        LogLevel.warn => 'WRN',
        LogLevel.error => 'ERR',
        _ => level.toUpperCase().substring(0, 3),
      };

  static String _sourceTag(String source) => switch (source) {
        LogSource.engine => 'ENG',
        LogSource.agent => 'AGT',
        _ => source.toUpperCase().substring(0, 3),
      };

  static String _formatLogLine(AgentLog log) {
    final agent =
        log.agentKey == '_system' ? '' : '  [${log.agentKey}]';
    return '${_formatTime(parseDate(log.timestamp))}  '
        '${_sourceTag(log.source)}  '
        '${_levelTag(log.level)}'
        '$agent  '
        '${log.message}';
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(workspaceLogsProvider((
      runId: widget.runId,
      instanceId: null,
    )));

    return Column(
      children: [
        // ── Filters ──
        _buildFilterBar(),
        // ── Log output ──
        Expanded(
          child: Stack(
            children: [
              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const EmptyState(
                      icon: LucideIcons.terminal,
                      title: 'No Logs',
                      description: 'Log entries will appear as agents run.',
                    );
                  }

                  if (_autoScroll && logs.length > _previousCount) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                  }
                  _previousCount = logs.length;

                  final entries = logs
                      .map((log) => LogEntry(
                            _formatLogLine(log),
                            level: log.level,
                          ))
                      .toList();
                  final copyText =
                      entries.map((e) => e.text).join('\n');

                  return TerminalLogView(
                    logs: entries,
                    controller: _scrollController,
                    copyText: copyText,
                  );
                },
                loading: () => const Center(child: Spinner()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              if (!_autoScroll)
                Positioned(
                  right: Spacing.md,
                  bottom: Spacing.md,
                  child: Button(
                    label: 'Jump to bottom',
                    icon: LucideIcons.arrow_down,
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      _scrollToBottom();
                      setState(() => _autoScroll = true);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final levelFilters = ref.watch(logLevelFiltersProvider);
    final sourceFilters = ref.watch(logSourceFiltersProvider);
    final agentFilter = ref.watch(logAgentFilterProvider);
    final agentKeys = widget.agents.map((a) => a.agentKey).toSet().toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Level toggles
          ToggleGroup(
            type: ToggleGroupType.multiple,
            style: ToggleGroupStyle.grouped,
            iconMode: false,
            variant: ToggleVariant.outline,
            value: levelFilters,
            onChanged: (values) {
              ref.read(logLevelFiltersProvider.notifier).state = values;
            },
            children: const [
              ToggleGroupItem(value: 'debug', child: Text('Debug')),
              ToggleGroupItem(value: 'info', child: Text('Info')),
              ToggleGroupItem(value: 'warn', child: Text('Warning')),
              ToggleGroupItem(value: 'error', child: Text('Error')),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          // Source toggles
          ToggleGroup(
            type: ToggleGroupType.multiple,
            style: ToggleGroupStyle.grouped,
            iconMode: false,
            variant: ToggleVariant.outline,
            value: sourceFilters,
            onChanged: (values) {
              ref.read(logSourceFiltersProvider.notifier).state = values;
            },
            children: const [
              ToggleGroupItem(value: 'engine', child: Text('Engine')),
              ToggleGroupItem(value: 'agent', child: Text('Agent')),
            ],
          ),
          // Agent dropdown
          if (agentKeys.length > 1) ...[
            const SizedBox(width: Spacing.sm),
            _AgentFilterDropdown(
              agentKeys: agentKeys,
              selected: agentFilter,
              onChanged: (v) {
                ref.read(logAgentFilterProvider.notifier).state = v;
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Agent filter dropdown ──

class _AgentFilterDropdown extends StatelessWidget {
  const _AgentFilterDropdown({
    required this.agentKeys,
    required this.selected,
    required this.onChanged,
  });

  final List<String> agentKeys;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      value: selected,
      hint: 'All agents',
      width: 160,
      items: [
        for (final key in agentKeys) SelectItem(value: key, label: key),
      ],
      onChanged: (v) => onChanged(v),
    );
  }
}
