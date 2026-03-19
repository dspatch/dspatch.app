// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/engine_client.dart';
import '../../models/commands/commands.dart';
import '../../models/docker_types.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';

part 'engine_controller.g.dart';

/// Controller for user-initiated Docker operations on the Engine screen.
///
/// Follows the [ProviderController] pattern: `@riverpod` AsyncNotifier,
/// `AsyncValue.guard()` for simple operations, manual state management
/// for streamed operations.
@riverpod
class EngineController extends _$EngineController {
  @override
  Future<void> build() async {}

  EngineClient get _client => ref.read(engineClientProvider);

  // ─── Status ──────────────────────────────────────────────────────────

  /// Refreshes Docker status by invalidating the status provider.
  void refreshStatus() {
    ref.invalidate(dockerStatusProvider);
    ref.invalidate(engineHealthProvider);
  }

  // ─── Image lifecycle ─────────────────────────────────────────────────

  /// Builds the runtime image, streaming output to the operation console.
  ///
  /// The engine streams build output as ephemeral events (`build_log_line`),
  /// then emits `build_complete` or `build_failed` when done.
  Future<void> buildRuntimeImage() async {
    state = const AsyncLoading();
    _setInProgress(true);
    _appendLog('─── Build started ───');

    // Attach listener BEFORE sending command to avoid missing early lines.
    final completer = Completer<bool>();
    final subscription = _client.events.listen((event) {
      if (event.name == 'build_log_line') {
        final line = event.data['line'] as String?;
        if (line != null) _appendLog(line);
      } else if (event.name == 'build_complete') {
        if (!completer.isCompleted) completer.complete(true);
      } else if (event.name == 'build_failed') {
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    try {
      // Send command — returns immediately, build runs in background.
      await _client.send(BuildRuntimeImage());

      final success = await completer.future;

      if (success) {
        _appendLog('─── Build complete ───');
        ref.invalidate(dockerStatusProvider);
        toast('Runtime image built successfully', type: ToastType.success);
        state = const AsyncData(null);
      } else {
        final error = 'Build failed';
        _appendLog('ERROR: $error');
        toast('Image build failed', type: ToastType.error);
        state = AsyncError(error, StackTrace.current);
      }
    } catch (e) {
      _appendLog('ERROR: $e');
      toast('Image build failed: $e', type: ToastType.error);
      state = AsyncError(e, StackTrace.current);
    } finally {
      await subscription.cancel();
      _setInProgress(false);
    }
  }

  /// Deletes the runtime image after stopping and removing all dependent
  /// containers. Shows a confirmation dialog if containers exist.
  ///
  /// Returns `true` if the image was deleted, `false` if cancelled or failed.
  Future<bool> deleteRuntimeImageCascade(BuildContext context) async {
    // Check for dependent containers.
    List<ContainerSummary> containers;
    try {
      final response = await _client.send(ListContainers());
      containers = response.containers;
    } catch (_) {
      containers = [];
    }

    if (containers.isNotEmpty) {
      if (!context.mounted) return false;

      final running =
          containers.where((c) => c.state == 'running').length;
      final stopped = containers.length - running;

      final parts = <String>[];
      if (running > 0) parts.add('$running running');
      if (stopped > 0) parts.add('$stopped stopped');

      final confirmed = await ConfirmDeleteDialog.show(
        context: context,
        title: 'Delete Runtime Image',
        description:
            'This will stop and remove ${parts.join(' and ')} '
            'container${containers.length == 1 ? '' : 's'} '
            'before deleting the image. Continue?',
      );
      if (!confirmed) return false;
    }

    state = const AsyncLoading();
    _setInProgress(true);

    try {
      // 1. Stop running containers.
      final running = containers
          .where((c) => c.state == 'running')
          .toList();
      for (final c in running) {
        _appendLog('Stopping container ${_shortId(c.id)}...');
        await _client.send(StopContainer(id: c.id));
      }

      // 2. Remove all containers.
      for (final c in containers) {
        _appendLog('Removing container ${_shortId(c.id)}...');
        await _client.send(RemoveContainer(id: c.id));
      }

      // 3. Delete the image.
      _appendLog('Deleting runtime image...');
      await _client.send(DeleteRuntimeImage());
      _appendLog('Runtime image deleted');

      ref.invalidate(dockerStatusProvider);
      ref.invalidate(containerListProvider);
      toast('Runtime image deleted', type: ToastType.success);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      _appendLog('ERROR: $e');
      toast('Failed to delete image: $e', type: ToastType.error);
      state = AsyncError(e, StackTrace.current);
      return false;
    } finally {
      _setInProgress(false);
    }
  }

  /// Rebuilds the runtime image. If the image already exists, cascades
  /// through container stop/remove and image deletion first (with confirmation).
  Future<void> rebuildRuntimeImage(BuildContext context) async {
    final status = ref.read(dockerStatusProvider).valueOrNull;
    if (status != null && status.hasRuntimeImage) {
      final deleted = await deleteRuntimeImageCascade(context);
      if (!deleted) return; // User cancelled.
    }
    await buildRuntimeImage();
  }

  // ─── Single container operations ─────────────────────────────────────

  /// Stops a single container.
  Future<bool> stopContainer(String id) => _loggedOp(
        action: () async { await _client.send(StopContainer(id: id)); },
        logStart: 'Stopping container ${_shortId(id)}...',
        logSuccess: 'Container ${_shortId(id)} stopped',
        toastSuccess: 'Container stopped',
        toastFailure: 'Failed to stop container',
        providerToInvalidate: containerListProvider,
      );

  /// Removes a single container.
  Future<bool> removeContainer(String id) => _loggedOp(
        action: () async { await _client.send(RemoveContainer(id: id)); },
        logStart: 'Removing container ${_shortId(id)}...',
        logSuccess: 'Container ${_shortId(id)} removed',
        toastSuccess: 'Container removed',
        toastFailure: 'Failed to remove container',
        providerToInvalidate: containerListProvider,
      );

  // ─── Bulk operations ─────────────────────────────────────────────────

  /// Stops all running d:spatch containers.
  Future<bool> stopAllContainers() => _bulkOp(
        action: () async {
          final result = await _client.send(StopAllContainers());
          return result.count;
        },
        logMessage: (c) => 'Stopped $c container${c == 1 ? '' : 's'}',
        successMessage: (c) => 'Stopped $c container${c == 1 ? '' : 's'}',
        failureMessage: 'Failed to stop containers',
      );

  /// Removes all stopped d:spatch containers.
  Future<bool> deleteStoppedContainers() => _bulkOp(
        action: () async {
          final result = await _client.send(DeleteStoppedContainers());
          return result.count;
        },
        logMessage: (c) =>
            'Removed $c stopped container${c == 1 ? '' : 's'}',
        successMessage: (c) => 'Removed $c container${c == 1 ? '' : 's'}',
        failureMessage: 'Failed to remove containers',
      );

  /// Removes orphaned containers.
  Future<bool> cleanOrphaned() => _bulkOp(
        action: () async {
          final result = await _client.send(CleanOrphanedContainers());
          return result.count;
        },
        logMessage: (c) =>
            'Cleaned $c orphaned container${c == 1 ? '' : 's'}',
        successMessage: (c) => 'Cleaned $c container${c == 1 ? '' : 's'}',
        failureMessage: 'Failed to clean orphaned containers',
      );

  // ─── Operation helpers ──────────────────────────────────────────────

  /// Runs a simple async operation with console logging, toast, and provider
  /// invalidation. All single-item operations use this helper so every action
  /// is visible in the operation console.
  Future<bool> _loggedOp({
    required Future<void> Function() action,
    required String logStart,
    required String logSuccess,
    required String toastSuccess,
    required String toastFailure,
    required ProviderOrFamily providerToInvalidate,
  }) async {
    state = const AsyncLoading();
    _setInProgress(true);
    _appendLog(logStart);
    try {
      await action();
      _appendLog(logSuccess);
      ref.invalidate(providerToInvalidate);
      toast(toastSuccess, type: ToastType.success);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      _appendLog('ERROR: $e');
      toast(toastFailure, type: ToastType.error);
      state = AsyncError(e, StackTrace.current);
      return false;
    } finally {
      _setInProgress(false);
    }
  }

  /// Runs a bulk operation that returns a count, with logging and progress.
  Future<bool> _bulkOp({
    required Future<int> Function() action,
    required String Function(int count) logMessage,
    required String Function(int count) successMessage,
    required String failureMessage,
  }) async {
    state = const AsyncLoading();
    _setInProgress(true);
    try {
      final count = await action();
      _appendLog(logMessage(count));
      ref.invalidate(containerListProvider);
      toast(successMessage(count), type: ToastType.success);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      _appendLog('ERROR: $e');
      toast(failureMessage, type: ToastType.error);
      state = AsyncError(e, StackTrace.current);
      return false;
    } finally {
      _setInProgress(false);
    }
  }

  // ─── Console helpers ─────────────────────────────────────────────────

  /// Clears the operation console.
  void clearLogs() => _clearLogs();

  void _appendLog(String line) {
    final current = ref.read(operationLogsProvider);
    final updated = [...current, line];
    // Cap at 1000 entries to prevent unbounded memory growth.
    ref.read(operationLogsProvider.notifier).state =
        updated.length > 1000 ? updated.sublist(updated.length - 1000) : updated;
  }

  void _clearLogs() {
    ref.read(operationLogsProvider.notifier).state = [];
  }

  void _setInProgress(bool value) {
    ref.read(operationInProgressProvider.notifier).state = value;
  }

  /// Returns the first 12 characters of a container ID for display.
  static String _shortId(String id) =>
      id.length > 12 ? id.substring(0, 12) : id;
}
