// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../main.dart' show kEnginePort;

/// Collapsible "Engine Details" panel — key-value table showing config,
/// connection, and runtime image info.
class EngineDetailsPanel extends ConsumerStatefulWidget {
  const EngineDetailsPanel({super.key});

  @override
  ConsumerState<EngineDetailsPanel> createState() => _EngineDetailsPanelState();
}

class _EngineDetailsPanelState extends ConsumerState<EngineDetailsPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(engineHealthProvider);
    final wsConnected = ref.watch(engineSessionProvider);

    final healthData = health.valueOrNull;

    return DspatchCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.settings, size: 14,
                      color: AppColors.mutedForeground),
                  const SizedBox(width: Spacing.sm),
                  const Text(
                    'Engine Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
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
          // Body
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg, 0, Spacing.lg, Spacing.lg,
                    ),
                    child: Column(
                      children: [
                        const Separator(),
                        const SizedBox(height: Spacing.md),
                        _DetailRow(
                          label: 'Client API Port',
                          value: '$kEnginePort',
                        ),
                        _DetailRow(
                          label: 'WebSocket',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.circle,
                                size: 8,
                                color: wsConnected
                                    ? AppColors.success
                                    : AppColors.destructive,
                              ),
                              const SizedBox(width: Spacing.xs),
                              Text(
                                wsConnected ? 'Connected' : 'Disconnected',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppFonts.mono,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DetailRow(
                          label: 'Connected Devices',
                          value: '${healthData?.connectedDevices ?? 0}',
                        ),
                        _DetailRow(
                          label: 'Backend URL',
                          value: healthData?.backendUrl ?? '—',
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A single row in the details panel: label on the left, value on the right.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.child,
  }) : assert(value != null || child != null);

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: AppFonts.mono,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
