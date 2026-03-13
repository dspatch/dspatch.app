// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/engine_health.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Health endpoint', () {
    test('returns running status', () async {
      final health = EngineHealth(host: harness.host, port: harness.port);
      final status = await health.checkHealth();
      health.dispose();

      expect(status, isNotNull);
      expect(status!.isRunning, isTrue);
      expect(status.uptimeSeconds, greaterThanOrEqualTo(0));
    });
  });

  group('Anonymous auth', () {
    test('returns session token and anonymous mode', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      final result = await auth.authenticateAnonymous();
      auth.dispose();

      expect(result.sessionToken, isNotEmpty);
      expect(result.authMode, equals('anonymous'));
    });
  });

  group('WebSocket connection', () {
    test('connects with valid token', () {
      expect(harness.client.isConnected, isTrue);
    });

    test('rejects invalid token', () async {
      final connection = EngineConnection(
        host: harness.host,
        port: harness.port,
        token: 'garbage-token',
      );

      expect(() => connection.connect(), throwsA(anything));
      connection.dispose();
    });

    test('rejects empty token', () async {
      final connection = EngineConnection(
        host: harness.host,
        port: harness.port,
        token: '',
      );

      expect(() => connection.connect(), throwsA(anything));
      connection.dispose();
    });
  });

  group('Auth endpoints', () {
    test('login returns service unavailable', () async {
      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/login',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: '{"username":"test","password":"test"}',
      );

      expect(response.statusCode, equals(503));
    });

    test('register returns service unavailable', () async {
      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/register',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: '{"username":"test","email":"test@test.com","password":"test"}',
      );

      expect(response.statusCode, equals(503));
    });
  });
}
