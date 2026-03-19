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

  /// The PID of the engine process spawned by [start], if any.
  int? _enginePid;

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
      final process = await Process.start(
        engineBinaryPath,
        [],
        mode: ProcessStartMode.detached,
        environment: {
          'DSPATCH_PORT': port.toString(),
        },
      );
      _enginePid = process.pid;
      // Write PID file for recovery in case the in-memory PID is lost.
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final pidFile = File('$appDir/engine.pid');
      await pidFile.writeAsString('${process.pid}');
      developer.log(
        'Engine spawned with PID ${process.pid}',
        name: 'EngineProcessManager',
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

  /// Stops the engine process.
  ///
  /// Attempts a graceful HTTP shutdown via `POST /shutdown` first.
  /// Falls back to killing the process by stored PID (or the PID file).
  ///
  /// Returns `true` if a stop was attempted, `false` if the engine was not
  /// running or no PID could be resolved.
  Future<bool> stop() async {
    final existing = await _health.checkHealth();
    if (existing == null || !existing.isRunning) return false;

    // 1. Try graceful HTTP shutdown.
    try {
      final client = HttpClient();
      final request = await client
          .post(host, port, '/shutdown')
          .timeout(const Duration(seconds: 5));
      await request.close().timeout(const Duration(seconds: 5));
      client.close();
      developer.log(
        'Engine stopped via HTTP /shutdown',
        name: 'EngineProcessManager',
      );
      return true;
    } catch (_) {
      // Engine may be unresponsive — fall through to PID kill.
    }

    // 2. Fallback: kill by stored PID or PID file.
    final pid = _enginePid ?? await _readPidFile();
    if (pid == null) {
      developer.log(
        'No PID available to stop engine',
        name: 'EngineProcessManager',
      );
      return false;
    }

    try {
      Process.killPid(pid, ProcessSignal.sigterm);
      developer.log(
        'Sent SIGTERM to engine (PID $pid)',
        name: 'EngineProcessManager',
      );
    } catch (e) {
      developer.log(
        'Failed to kill engine PID $pid: $e',
        name: 'EngineProcessManager',
      );
    }

    // Clean up PID file.
    await _deletePidFile();
    _enginePid = null;
    return true;
  }

  /// Reads the engine PID from the on-disk PID file, or returns `null`.
  Future<int?> _readPidFile() async {
    try {
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final pidFile = File('$appDir/engine.pid');
      if (!pidFile.existsSync()) return null;
      final contents = (await pidFile.readAsString()).trim();
      return int.tryParse(contents);
    } catch (_) {
      return null;
    }
  }

  /// Deletes the PID file if it exists.
  Future<void> _deletePidFile() async {
    try {
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final pidFile = File('$appDir/engine.pid');
      if (pidFile.existsSync()) await pidFile.delete();
    } catch (_) {}
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
