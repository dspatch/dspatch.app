// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
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

  group('Backend auth — login endpoint (requires localhost:3000)', () {
    test('POST /auth/login with invalid credentials returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.login(
            username: 'nonexistent_test_user_xyz',
            password: 'definitely_wrong_password',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.statusCode,
              'statusCode',
              isIn([400, 401, 403, 422]),
            ),
          ),
        );
      } finally {
        auth.dispose();
      }
    });

    test('POST /auth/login with empty credentials returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.login(username: '', password: ''),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });

    test('POST /auth/login error response has structured body', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // Use raw HTTP to inspect the response shape directly.
      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/login',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'nonexistent_test_user_xyz',
          'password': 'wrong',
        }),
      );

      // Should be an error status, not 200.
      expect(response.statusCode, isNot(200));

      // Response body should be valid JSON with an 'error' field.
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body, contains('error'));
      expect(body['error'], isA<String>());
      expect(body['error'], isNotEmpty);
    });
  });

  group('Backend auth — register endpoint (requires localhost:3000)', () {
    test('POST /auth/register with invalid email returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.register(
            username: 'test_user_register',
            email: 'not-a-valid-email',
            password: 'ValidPassword123!',
          ),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });

    test('POST /auth/register with short password returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.register(
            username: 'test_user_register',
            email: 'test@example.com',
            password: 'ab',
          ),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });

    test('POST /auth/register error response has structured body', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/register',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'x',
          'email': 'bad',
          'password': 'a',
        }),
      );

      expect(response.statusCode, isNot(200));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body, contains('error'));
    });
  });

  group('Backend auth — anonymous auth limitations', () {
    test('anonymous session cannot register a device', () async {
      // The harness is authenticated as anonymous. Device management
      // requires a real account, so this command should be rejected.
      expect(
        () => harness.client.registerDevice(request: {
          'device_name': 'test-device',
          'device_type': 'desktop',
        }),
        throwsA(isA<EngineException>()),
      );
    });

    test('anonymous auth is reflected in health endpoint', () async {
      final health = EngineHealth(host: harness.host, port: harness.port);
      final status = await health.checkHealth();
      health.dispose();

      expect(status, isNotNull);
      // After anonymous auth, the engine reports authenticated state.
      expect(status!.authenticated, isTrue);
    });
  });

  group('Backend auth — engine proxies to backend', () {
    test('login request reaches the backend (not rejected locally)',
        () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // When the backend IS available, the engine should proxy the login
      // request and return a backend-originated response (not 503).
      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/login',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'nonexistent_test_user_xyz',
          'password': 'wrong',
        }),
      );

      // The engine should NOT return 503 (service unavailable) when the
      // backend is reachable. It should return a proper auth error.
      expect(response.statusCode, isNot(503));
    });

    test('register request reaches the backend (not rejected locally)',
        () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/register',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'proxy_test_user',
          'email': 'proxy@test.com',
          'password': 'TestPassword123!',
        }),
      );

      // Should not be 503 — the engine should proxy to the real backend.
      expect(response.statusCode, isNot(503));
    });
  });
}
