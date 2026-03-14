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

  group('Agent template resolution (requires localhost:3000)', () {
    test('resolve non-existent agent returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand(
          'resolve_hub_agent',
          {'slug': 'nonexistent-agent-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('resolve non-existent workspace returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand(
          'resolve_hub_workspace',
          {'slug': 'nonexistent-ws-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('check versions with empty slugs', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // Empty slugs may return an empty result or an error — test actual
      // behavior and verify it doesn't crash.
      try {
        final result = await harness.client.sendCommand(
          'check_agent_versions',
          {'slugs': ''},
        );
        // If it succeeds, the result should be a valid map.
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException {
        // An error response is also acceptable for empty input.
      }
    });

    test('check versions with non-existent slugs', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      try {
        final result = await harness.client.sendCommand(
          'check_agent_versions',
          {'slugs': 'fake-agent-1,fake-agent-2'},
        );
        // Should return a valid structure — versions will be empty or null
        // for slugs that don't exist.
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException {
        // A NOT_FOUND or similar error is acceptable for unknown slugs.
      }
    });

    test('check workspace versions with non-existent', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      try {
        final result = await harness.client.sendCommand(
          'check_workspace_versions',
          {'slugs': 'fake-ws-1'},
        );
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException {
        // A NOT_FOUND or similar error is acceptable for unknown slugs.
      }
    });

    // TODO: Add happy-path tests when the hub has seeded test agents
    // (e.g. dspatch://agent/test/echo)
  });
}
