// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';
import 'dart:io';

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/engine_health.dart';
import 'package:dspatch_app/database/engine_database.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;

/// Integration test harness for the dspatch engine.
///
/// Connects to a running engine instance, authenticates as anonymous,
/// and provides an [EngineClient] + read-only [EngineDatabase].
///
/// Usage:
///   1. Start the engine: `cargo run --bin dspatch-daemon` (or with `--test-db`)
///   2. Run tests: `dart test integration_test/`
///
/// The harness auto-discovers the DB path via `GET /engine-info`.
/// Port defaults to 9847 (override with `DSPATCH_TEST_PORT` env var).
class TestHarness {
  final int port;
  String? _dbPath;
  String get dbPath => _dbPath!;

  EngineClient? _client;
  EngineDatabase? _database;

  EngineClient get client => _client!;
  EngineDatabase get database => _database!;

  bool? _dockerAvailable;
  bool? _backendAvailable;

  TestHarness({required this.port});

  /// Creates a harness using default port (9847) or `DSPATCH_TEST_PORT` env var.
  factory TestHarness.fromEnv() {
    final portStr = Platform.environment['DSPATCH_TEST_PORT'];
    final port = portStr != null ? int.parse(portStr) : 9847;
    return TestHarness(port: port);
  }

  String get host => '127.0.0.1';

  Future<void> setUp() async {
    // 1. Query engine-info to discover DB path.
    final infoResponse = await http
        .get(Uri.parse('http://$host:$port/engine-info'))
        .timeout(const Duration(seconds: 5));
    if (infoResponse.statusCode != 200) {
      throw StateError(
        'Engine not reachable at $host:$port. '
        'Start it with: cargo run --bin dspatch-daemon -- --test-db',
      );
    }
    final info = jsonDecode(infoResponse.body) as Map<String, dynamic>;
    _dbPath = info['db_path'] as String;

    // 2. Authenticate as anonymous.
    final auth = EngineAuth(host: host, port: port);
    final authResult = await auth.authenticateAnonymous();
    auth.dispose();

    // 3. Connect WebSocket.
    final connection = EngineConnection(
      host: host,
      port: port,
      token: authResult.sessionToken,
    );
    await connection.connect();

    // 4. Create engine client (owns the connection).
    _client = EngineClient(connection);

    // 5. Open Drift database.
    // Note: We don't set PRAGMA query_only because Drift needs to write
    // the user_version pragma for migration bookkeeping. The DB is
    // effectively read-only since the migration strategy is a no-op.
    _database = EngineDatabase.forTesting(
      NativeDatabase(File(dbPath)),
    );
  }

  Future<bool> isDockerAvailable() async {
    if (_dockerAvailable != null) return _dockerAvailable!;
    final health = EngineHealth(host: host, port: port);
    final status = await health.checkHealth();
    health.dispose();
    _dockerAvailable = status?.dockerAvailable ?? false;
    return _dockerAvailable!;
  }

  /// Checks if the dev backend is reachable at localhost:3000.
  Future<bool> isBackendAvailable() async {
    if (_backendAvailable != null) return _backendAvailable!;
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/health/live'))
          .timeout(const Duration(seconds: 3));
      _backendAvailable = response.statusCode == 200;
    } catch (_) {
      _backendAvailable = false;
    }
    return _backendAvailable!;
  }

  Future<void> tearDown() async {
    _client?.dispose();
    await _database?.close();
  }
}
