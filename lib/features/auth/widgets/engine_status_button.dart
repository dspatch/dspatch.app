// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';

/// Compact button showing engine status with start/stop control.
///
/// Polls the engine health endpoint every 2 seconds. Tapping the button
/// starts the engine when offline or stops it when running.
class EngineStatusButton extends ConsumerStatefulWidget {
  const EngineStatusButton({super.key});

  @override
  ConsumerState<EngineStatusButton> createState() => _EngineStatusButtonState();
}

class _EngineStatusButtonState extends ConsumerState<EngineStatusButton> {
  Timer? _pollTimer;
  bool _running = false;
  bool _busy = false; // true while starting or stopping

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_busy) return;
    final manager = ref.read(engineProcessManagerProvider);
    if (manager == null) return;
    final health = await manager.checkRunning();
    if (!mounted) return;
    final running = health != null && health.isRunning;
    if (running != _running) {
      setState(() => _running = running);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final manager = ref.read(engineProcessManagerProvider);
    if (manager == null) return;
    setState(() => _busy = true);

    try {
      if (_running) {
        await manager.stop();
      } else {
        await manager.start();
      }
    } catch (e) {
      if (mounted) {
        toast('Engine: $e', type: ToastType.error);
      }
    }

    // Re-check status after action.
    final health = await manager.checkRunning();
    if (!mounted) return;
    setState(() {
      _running = health != null && health.isRunning;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // On mobile, the engine runs in-process — no start/stop button needed.
    final manager = ref.read(engineProcessManagerProvider);
    if (manager == null) return const SizedBox.shrink();
    final Color dotColor;
    final String label;
    final IconData icon;

    if (_busy) {
      dotColor = AppColors.warning;
      label = _running ? 'Stopping...' : 'Starting...';
      icon = LucideIcons.loader;
    } else if (_running) {
      dotColor = AppColors.success;
      label = 'Engine';
      icon = LucideIcons.square;
    } else {
      dotColor = AppColors.destructive;
      label = 'Engine';
      icon = LucideIcons.play;
    }

    return Tooltip(
      message: _running ? 'Stop engine' : 'Start engine',
      child: MouseRegion(
        cursor: _busy ? SystemMouseCursors.wait : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _busy ? null : _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: AppColors.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
