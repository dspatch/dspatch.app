// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';

import 'package:dspatch_app/engine_client/backend_auth.dart';
import 'package:dspatch_app/engine_client/engine_auth.dart';
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

  group('Backend auth — direct backend login (requires localhost:3000)', () {
    test('BackendAuth.login with invalid credentials throws', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final backend = BackendAuth(baseUrl: 'http://localhost:3000');
      expect(
        () => backend.login(
          username: 'nonexistent_test_user_xyz',
          password: 'definitely_wrong_password',
        ),
        throwsA(isA<BackendAuthException>()),
      );
    });

    test('BackendAuth.login with empty credentials throws', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final backend = BackendAuth(baseUrl: 'http://localhost:3000');
      expect(
        () => backend.login(username: '', password: ''),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });

  group('Backend auth — direct backend register (requires localhost:3000)', () {
    test('BackendAuth.register with invalid email throws', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final backend = BackendAuth(baseUrl: 'http://localhost:3000');
      expect(
        () => backend.register(
          username: 'test_user_register',
          email: 'not-a-valid-email',
          password: 'ValidPassword123!',
        ),
        throwsA(isA<BackendAuthException>()),
      );
    });

    test('BackendAuth.register with short password throws', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final backend = BackendAuth(baseUrl: 'http://localhost:3000');
      expect(
        () => backend.register(
          username: 'test_user_register',
          email: 'test@example.com',
          password: 'ab',
        ),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });

  group('Engine auth — connect endpoint', () {
    test('connect with invalid token returns error', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.connect(backendToken: 'invalid-jwt-token'),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });

    test('connect with empty token returns error', () async {
      final auth = EngineAuth(host: harness.host, port: harness.port);
      try {
        expect(
          () => auth.connect(backendToken: ''),
          throwsA(isA<AuthException>()),
        );
      } finally {
        auth.dispose();
      }
    });
  });

  group('Backend auth — anonymous auth limitations', () {
    test('anonymous auth is reflected in health endpoint', () async {
      final health = EngineHealth(host: harness.host, port: harness.port);
      final status = await health.checkHealth();
      health.dispose();

      expect(status, isNotNull);
      // After anonymous auth, the engine reports authenticated state.
      expect(status!.authenticated, isTrue);
    });
  });

  group('Backend auth — engine /auth/connect endpoint', () {
    test('connect request with bad JWT returns structured error', () async {
      final uri = Uri.parse(
        'http://${harness.host}:${harness.port}/auth/connect',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'backend_token': 'not-a-real-jwt'}),
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
}
