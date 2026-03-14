// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
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

  group('Backend auth (requires localhost:3000)', () {
    // NOTE: login, register, auth_status, and logout are NOT wired as
    // WebSocket commands in the engine's Command enum. They are handled
    // through HTTP endpoints (EngineAuth). Sending them as WebSocket
    // commands yields INVALID_PARAMS. These tests verify the engine
    // responds gracefully to unrecognized command names.

    test('login via WebSocket returns INVALID_PARAMS', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('login', {
          'username': 'nonexistent_test_user_xyz',
          'password': 'wrong',
        }),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'INVALID_PARAMS'),
        ),
      );
    });

    test('register via WebSocket returns INVALID_PARAMS', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('register', {
          'username': 'test_user',
          'email': 'not-an-email',
          'password': 'short',
        }),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'INVALID_PARAMS'),
        ),
      );
    });

    test('auth_status via WebSocket returns INVALID_PARAMS', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('auth_status', {}),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'INVALID_PARAMS'),
        ),
      );
    });

    test('logout via WebSocket returns INVALID_PARAMS', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('logout', {}),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'INVALID_PARAMS'),
        ),
      );
    });
  });
}
