// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

import '../../../di/providers.dart';
import '../engine_controller.dart';

/// Collapsible terminal log viewer for Docker build output and operation results.
///
/// Always visible as a collapsed header. Auto-expands when an operation starts,
/// auto-scrolls to bottom on new log lines.
class OperationConsole extends ConsumerStatefulWidget {
  const OperationConsole({super.key});

  @override
  ConsumerState<OperationConsole> createState() => _OperationConsoleState();
}

class _OperationConsoleState extends ConsumerState<OperationConsole> {
  final _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(operationLogsProvider);
    final inProgress = ref.watch(operationInProgressProvider);

    // Auto-expand when an operation starts.
    ref.listen<bool>(operationInProgressProvider, (prev, next) {
      if (next && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });

    // Auto-scroll when new log lines arrive.
    ref.listen<List<String>>(operationLogsProvider, (prev, next) {
      if (_isExpanded && next.isNotEmpty) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });

    return DspatchCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.terminal,
                    size: 14,
                    color: inProgress
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Text(
                    'Operation Console',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  if (logs.isNotEmpty)
                    DspatchBadge(
                      label: '${logs.length}',
                      variant: BadgeVariant.secondary,
                    ),
                  if (inProgress) ...[
                    const SizedBox(width: Spacing.sm),
                    const Spinner(size: SpinnerSize.sm, color: AppColors.primary),
                  ],
                  const Spacer(),
                  if (logs.isNotEmpty && !inProgress)
                    Button(
                      label: 'Clear',
                      variant: ButtonVariant.ghost,
                      onPressed: () => ref
                          .read(engineControllerProvider.notifier)
                          .clearLogs(),
                    ),
                  Icon(
                    _isExpanded
                        ? LucideIcons.chevron_up
                        : LucideIcons.chevron_down,
                    size: 16,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          // Expandable console body
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? TerminalLogView(
                    logs: logs.map((l) => LogEntry(l)).toList(),
                    maxHeight: 400,
                    expand: false,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    controller: _scrollController,
                    copyText: logs.join('\n'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
