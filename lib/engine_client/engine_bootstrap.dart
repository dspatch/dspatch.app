// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:developer' as developer;

import 'engine_auth.dart';
import 'engine_client.dart';
import 'engine_connection.dart';
import 'engine_health.dart';
import 'engine_process_manager.dart';

/// Configuration for the engine bootstrap sequence.
class EngineBootstrapConfig {
  /// Host where the engine listens.
  final String host;

  /// Port where the engine's client API listens.
  final int port;

  /// When true, skip engine spawning (dev mode).
  ///
  /// Set via `--dart-define=ENGINE_EXTERNAL=true` at compile time,
  /// or override directly in this config.
  final bool engineExternal;

  const EngineBootstrapConfig({
    this.host = '127.0.0.1',
    this.port = 9847,
    this.engineExternal = const bool.fromEnvironment('ENGINE_EXTERNAL'),
  });
}

/// Result of a successful engine bootstrap.
///
/// Contains the connected [EngineClient] and the [HealthStatus] of the engine
/// at the time of connection.
class EngineBootstrapResult {
  final EngineClient client;
  final HealthStatus healthStatus;
  final AuthResult authResult;

  const EngineBootstrapResult({
    required this.client,
    required this.healthStatus,
    required this.authResult,
  });
}

/// Orchestrates the full engine client startup sequence.
///
/// 1. Ensure the engine process is running (via [EngineProcessManager])
/// 2. Authenticate (via [EngineAuth])
/// 3. Open WebSocket connection (via [EngineConnection])
/// 4. Return a ready-to-use [EngineClient]
///
/// This class is pure Dart — no Flutter imports.
class EngineBootstrap {
  final EngineBootstrapConfig config;

  EngineBootstrap(this.config);

  /// Initializes the engine client, performing the full startup sequence.
  ///
  /// Throws [EngineStartException] if the engine cannot be started.
  /// Throws [AuthException] if authentication fails.
  /// Throws on WebSocket connection failure.
  Future<EngineBootstrapResult> initialize() async {
    developer.log(
      'Starting engine bootstrap (port: ${config.port}, external: ${config.engineExternal})',
      name: 'EngineBootstrap',
    );

    // Step 1: Ensure engine is running.
    final processManager = EngineProcessManager(
      engineBinaryPath: EngineProcessManager.resolveEngineBinaryPath(),
      host: config.host,
      port: config.port,
      engineExternal: config.engineExternal,
    );

    final healthStatus = await processManager.ensureRunning();
    developer.log(
      'Engine is running: ${healthStatus.status}',
      name: 'EngineBootstrap',
    );

    // Step 2: Authenticate.
    final auth = EngineAuth(host: config.host, port: config.port);
    final authResult = await auth.authenticateAnonymous();
    developer.log(
      'Authenticated: ${authResult.authMode}',
      name: 'EngineBootstrap',
    );

    // Step 3: Connect WebSocket.
    final connection = EngineConnection(
      host: config.host,
      port: config.port,
      token: authResult.sessionToken,
    );
    await connection.connect();
    developer.log(
      'WebSocket connected',
      name: 'EngineBootstrap',
    );

    // Step 4: Return ready client.
    final client = EngineClient(connection);

    return EngineBootstrapResult(
      client: client,
      healthStatus: healthStatus,
      authResult: authResult,
    );
  }
}
