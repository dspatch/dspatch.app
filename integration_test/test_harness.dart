// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:io';

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/engine_health.dart';
import 'package:dspatch_app/database/engine_database.dart';
import 'package:drift/native.dart';

class TestHarness {
  final int port;
  final String dbPath;

  late final EngineClient client;
  late final EngineDatabase database;

  bool? _dockerAvailable;

  TestHarness({required this.port, required this.dbPath});

  factory TestHarness.fromEnv() {
    final portStr = Platform.environment['DSPATCH_TEST_PORT'];
    final dbPath = Platform.environment['DSPATCH_TEST_DB'];

    if (portStr == null || dbPath == null) {
      throw StateError(
        'Missing env vars. Start engine with --test-db, then set:\n'
        '  DSPATCH_TEST_PORT=<port>\n'
        '  DSPATCH_TEST_DB=<db_dir>/engine.db',
      );
    }

    return TestHarness(port: int.parse(portStr), dbPath: dbPath);
  }

  String get host => '127.0.0.1';

  Future<void> setUp() async {
    // 1. Authenticate as anonymous
    final auth = EngineAuth(host: host, port: port);
    final authResult = await auth.authenticateAnonymous();
    auth.dispose();

    // 2. Connect WebSocket
    final connection = EngineConnection(
      host: host,
      port: port,
      token: authResult.sessionToken,
    );
    await connection.connect();

    // 3. Create engine client (owns the connection)
    client = EngineClient(connection);

    // 4. Open Drift database (read-only)
    database = EngineDatabase.forTesting(
      NativeDatabase(File(dbPath), setup: (db) {
        db.execute('PRAGMA query_only = ON');
      }),
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

  Future<void> tearDown() async {
    client.dispose();
    await database.close();
  }
}
