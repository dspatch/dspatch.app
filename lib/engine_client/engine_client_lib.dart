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
/// final auth = EngineAuth(host: '127.0.0.1', port: 9847);
/// final result = await auth.authenticateAnonymous();
///
/// final connection = EngineConnection(
///   host: '127.0.0.1',
///   port: 9847,
///   token: result.sessionToken,
/// );
/// await connection.connect();
///
/// final client = EngineClient(connection);
/// await client.send(LaunchWorkspace(id: 'workspace-id'));
/// ```
library;

export 'backend_auth.dart';
export 'engine_auth.dart';
export 'engine_client.dart';
export 'engine_connection.dart';
export 'engine_health.dart';
export 'engine_process_manager.dart';
export 'models/auth_state.dart';
export 'protocol/protocol.dart';
