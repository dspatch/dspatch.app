// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:developer' as developer;
import 'dart:io';

import 'engine_health.dart';

/// Manages the lifecycle of the dspatch engine process on desktop.
///
/// Provides [start] and [stop] methods for on-demand engine control,
/// and [checkRunning] to poll the engine's health endpoint.
///
/// This class is pure Dart — no Flutter imports.
class EngineProcessManager {
  final String engineBinaryPath;
  final String host;
  final int port;

  late final EngineHealth _health;

  EngineProcessManager({
    required this.engineBinaryPath,
    required this.host,
    required this.port,
    EngineHealth? health,
  }) : _health = health ?? EngineHealth(host: host, port: port);

  /// Returns the current [HealthStatus], or `null` if the engine is not
  /// reachable.
  Future<HealthStatus?> checkRunning() => _health.checkHealth();

  /// Spawns the engine as a detached process and waits for it to become
  /// healthy.
  ///
  /// Returns [HealthStatus] on success.
  /// Throws [EngineStartException] if the engine cannot be started.
  Future<HealthStatus> start({
    Duration startupTimeout = const Duration(seconds: 30),
  }) async {
    // Check if already running.
    final existing = await _health.checkHealth();
    if (existing != null && existing.isRunning) {
      developer.log(
        'Engine already running (uptime: ${existing.uptimeSeconds}s)',
        name: 'EngineProcessManager',
      );
      return existing;
    }

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

    developer.log('Engine is ready', name: 'EngineProcessManager');
    return status;
  }

  /// Stops the engine by finding its PID via port and sending SIGTERM.
  ///
  /// Returns `true` if the engine was stopped, `false` if it wasn't running
  /// or couldn't be stopped.
  Future<bool> stop() async {
    final existing = await _health.checkHealth();
    if (existing == null || !existing.isRunning) return false;

    try {
      // Find the PID of the process *listening* on the engine port.
      // -sTCP:LISTEN ensures we only match the server, not connected clients
      // (which would include this app).
      final result = await Process.run(
        'lsof',
        ['-ti', 'tcp:$port', '-sTCP:LISTEN'],
      );

      final output = (result.stdout as String).trim();
      if (output.isEmpty) return false;

      // lsof may return multiple PIDs (one per line). Kill them all.
      for (final pidStr in output.split('\n')) {
        final pid = int.tryParse(pidStr.trim());
        if (pid != null) {
          Process.killPid(pid, ProcessSignal.sigterm);
        }
      }

      developer.log('Sent SIGTERM to engine', name: 'EngineProcessManager');
      return true;
    } catch (e) {
      developer.log(
        'Failed to stop engine: $e',
        name: 'EngineProcessManager',
      );
      return false;
    }
  }

  /// Resolves the path to the engine binary based on the current platform
  /// and the app's own executable location.
  ///
  /// On Windows: `dspatch-engine.exe` next to the app binary.
  /// On macOS/Linux: `dspatch-engine` next to the app binary.
  static String resolveEngineBinaryPath() {
    final appDir = File(Platform.resolvedExecutable).parent.path;
    final binaryName =
        Platform.isWindows ? 'dspatch-engine.exe' : 'dspatch-engine';
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
