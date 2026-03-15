// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Pure-Dart engine client library.
///
/// Connects the Flutter app (GUI) and future CLI to the dspatch engine's
/// Client API over WebSocket. No Flutter imports — shared by all client modes.
///
/// Usage:
/// ```dart
/// import 'package:dspatch_app/engine_client/engine_client_lib.dart';
///
/// final bootstrap = EngineBootstrap(EngineBootstrapConfig());
/// final result = await bootstrap.initialize();
/// final client = result.client;
///
/// // Send typed commands.
/// await client.send(LaunchWorkspace(id: 'workspace-id'));
///
/// // Listen for table invalidations.
/// client.invalidations.listen((tables) {
///   database.notifyUpdates(tables); // Drift re-queries
/// });
/// ```
library;

export 'backend_auth.dart';
export 'engine_auth.dart';
export 'engine_bootstrap.dart';
export 'engine_client.dart';
export 'engine_connection.dart';
export 'engine_health.dart';
export 'engine_process_manager.dart';
export 'models/auth_state.dart';
export 'protocol/protocol.dart';
