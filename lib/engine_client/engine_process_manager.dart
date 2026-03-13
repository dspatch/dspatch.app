// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:developer' as developer;
import 'dart:io';

import 'engine_health.dart';

/// Manages the lifecycle of the dspatch engine process on desktop.
///
/// On startup:
/// 1. Checks if the engine is already running via `/health`
/// 2. If not running and [engineExternal] is false, spawns it as a detached process
/// 3. Polls `/health` until the engine is ready
///
/// When [engineExternal] is true (set via `--dart-define=ENGINE_EXTERNAL=true`),
/// spawning is skipped entirely — the developer is expected to run the engine
/// manually via `cargo run --bin dspatch-engine`.
///
/// This class is pure Dart — no Flutter imports.
class EngineProcessManager {
  final String engineBinaryPath;
  final String host;
  final int port;
  final bool engineExternal;

  late final EngineHealth _health;

  EngineProcessManager({
    required this.engineBinaryPath,
    required this.host,
    required this.port,
    required this.engineExternal,
    EngineHealth? health,
  }) : _health = health ??
            EngineHealth(host: host, port: port);

  /// Whether the manager should attempt to spawn the engine binary.
  bool get shouldSpawn => !engineExternal;

  /// Ensures the engine is running and ready.
  ///
  /// Returns [HealthStatus] from the running engine.
  /// Throws if the engine cannot be started or doesn't become ready.
  Future<HealthStatus> ensureRunning({
    Duration startupTimeout = const Duration(seconds: 30),
  }) async {
    // Check if engine is already running.
    final existing = await _health.checkHealth();
    if (existing != null && existing.isRunning) {
      developer.log(
        'Engine already running (uptime: ${existing.uptimeSeconds}s)',
        name: 'EngineProcessManager',
      );
      return existing;
    }

    if (engineExternal) {
      throw EngineStartException(
        'ENGINE_EXTERNAL=true but engine is not running at $host:$port. '
        'Start it manually with: cargo run --bin dspatch-engine',
      );
    }

    // Spawn the engine.
    developer.log(
      'Spawning engine: $engineBinaryPath',
      name: 'EngineProcessManager',
    );

    try {
      await Process.start(
        engineBinaryPath,
        [],
        mode: ProcessStartMode.detached,
        environment: {
          'DSPATCH_PORT': port.toString(),
        },
      );
    } catch (e) {
      throw EngineStartException(
        'Failed to start engine binary at $engineBinaryPath: $e',
      );
    }

    // Poll /health until ready.
    developer.log(
      'Waiting for engine to be ready...',
      name: 'EngineProcessManager',
    );

    final ready = await _health.waitForReady(timeout: startupTimeout);
    if (!ready) {
      throw EngineStartException(
        'Engine did not become ready within ${startupTimeout.inSeconds}s',
      );
    }

    final status = await _health.checkHealth();
    if (status == null) {
      throw EngineStartException(
        'Engine health check passed during wait but failed on final check',
      );
    }

    developer.log(
      'Engine is ready',
      name: 'EngineProcessManager',
    );
    return status;
  }

  /// Resolves the path to the engine binary based on the current platform
  /// and the app's own executable location.
  ///
  /// On Windows: `dspatch-engine.exe` next to the app binary.
  /// On macOS/Linux: `dspatch-engine` next to the app binary.
  static String resolveEngineBinaryPath() {
    final appDir = File(Platform.resolvedExecutable).parent.path;
    final binaryName = Platform.isWindows
        ? 'dspatch-engine.exe'
        : 'dspatch-engine';
    return '$appDir/$binaryName';
  }

  void dispose() {
    _health.dispose();
  }
}

/// Exception thrown when the engine process cannot be started.
class EngineStartException implements Exception {
  final String message;
  const EngineStartException(this.message);

  @override
  String toString() => 'EngineStartException: $message';
}
