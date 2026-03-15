// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/engine_health.dart';
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
    test('returns running status with full response shape', () async {
      final health = EngineHealth(host: harness.host, port: harness.port);
      final status = await health.checkHealth();
      health.dispose();

      expect(status, isNotNull);
      expect(status!.isRunning, isTrue);
      expect(status.status, equals('running'));
      expect(status.uptimeSeconds, greaterThanOrEqualTo(0));
      // Validate all fields are present and have sane types.
      expect(status.dockerAvailable, isA<bool>());
      expect(status.authenticated, isA<bool>());
      expect(status.connectedDevices, isA<int>());
      expect(status.connectedDevices, greaterThanOrEqualTo(0));
    });

    test('returns null for unreachable engine', () async {
      final health = EngineHealth(host: harness.host, port: 1);
      final status = await health.checkHealth(
        timeout: const Duration(seconds: 2),
      );
      health.dispose();

      expect(status, isNull);
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

    test('multiple anonymous sessions return distinct tokens', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      final result1 = await auth.authenticateAnonymous();
      final result2 = await auth.authenticateAnonymous();
      auth.dispose();

      expect(result1.sessionToken, isNotEmpty);
      expect(result2.sessionToken, isNotEmpty);
      expect(result1.sessionToken, isNot(equals(result2.sessionToken)));
    });
  });

  group('WebSocket connection', () {
    test('connects with valid token and can send commands', () async {
      // The harness connection is already authenticated and connected.
      expect(harness.client.isConnected, isTrue);

      // Prove the connection is functional by sending a real command.
      // get_preference for a nonexistent key should return a result
      // (possibly with a null value) rather than throwing.
      final result = await harness.client.getPreference('_test_nonexistent');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('rejects invalid token with specific exception', () async {
      final connection = EngineConnection(
        host: harness.host,
        port: harness.port,
        token: 'garbage-token',
      );

      try {
        await expectLater(
          () => connection.connect(),
          throwsA(isA<Exception>()),
        );
      } finally {
        connection.dispose();
      }
    });

    test('rejects empty token with specific exception', () async {
      final connection = EngineConnection(
        host: harness.host,
        port: harness.port,
        token: '',
      );

      try {
        await expectLater(
          () => connection.connect(),
          throwsA(isA<Exception>()),
        );
      } finally {
        connection.dispose();
      }
    });
  });

  group('Auth endpoints — connect/refresh', () {
    test('connect with invalid JWT returns error', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.connect(backendToken: 'invalid-jwt'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.statusCode,
              'statusCode',
              isIn([400, 401, 403, 502, 503]),
            ),
          ),
        );
      } finally {
        auth.dispose();
      }
    });

    test('refresh with invalid session returns error', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.refresh(
            backendToken: 'invalid-jwt',
            sessionToken: 'nonexistent-session',
          ),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });
  });
}
