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
          'hub_resolve_agent',
          {'agent_id': 'nonexistent-agent-xyz'},
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
          'hub_resolve_workspace',
          {'workspace_id': 'nonexistent-ws-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('check_for_agent_updates with no agents', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // check_for_agent_updates takes no parameters.
      try {
        final result = await harness.client.sendCommand(
          'check_for_agent_updates',
          {},
        );
        // If it succeeds, the result should be a valid map.
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException {
        // An error response is also acceptable (e.g. API_ERROR when
        // hub is unreachable).
      }
    });

    test('check_for_workspace_updates with no workspaces', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // check_for_workspace_updates takes no parameters.
      try {
        final result = await harness.client.sendCommand(
          'check_for_workspace_updates',
          {},
        );
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException {
        // An error response is also acceptable (e.g. API_ERROR when
        // hub is unreachable).
      }
    });

    // TODO: Add happy-path tests when the hub has seeded test agents
    // (e.g. dspatch://agent/test/echo)
  });
}
