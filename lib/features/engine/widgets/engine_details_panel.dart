// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../main.dart' show kEnginePort;
import '../engine_controller.dart';

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
                        _DetailRow(
                          label: 'Router Version',
                          child: _RouterVersionSelector(),
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

/// Dropdown that fetches available router versions from GitHub via the engine
/// and persists the selection as the `router_version` preference.
class _RouterVersionSelector extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RouterVersionSelector> createState() =>
      _RouterVersionSelectorState();
}

class _RouterVersionSelectorState extends ConsumerState<_RouterVersionSelector> {
  List<String> _versions = [];
  String _selected = 'main';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(engineControllerProvider.notifier);
    final results = await Future.wait([
      controller.getRouterVersion(),
      controller.fetchRouterVersions(),
    ]);

    if (!mounted) return;

    final currentVersion = results[0] as String;
    final availableVersions = results[1] as List<String>;

    setState(() {
      _selected = currentVersion;
      _versions = availableVersions;
      // Ensure the current selection is in the list.
      if (!_versions.contains(_selected)) {
        _versions.insert(0, _selected);
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Spinner(size: SpinnerSize.sm);
    }

    return Select<String>(
      value: _selected,
      hint: 'Select version',
      items: _versions
          .map((v) => SelectItem(value: v, label: v))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _selected = v);
        ref.read(engineControllerProvider.notifier).setRouterVersion(v);
      },
      width: 200,
    );
  }
}
