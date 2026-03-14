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

  group('Community Hub browsing (requires localhost:3000)', () {
    test('browse agents returns paginated list', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_browse_agents',
        {'per_page': 5},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('browse agents with search', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_browse_agents',
        {'search': 'test', 'per_page': 5},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('browse workspaces returns list', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_browse_workspaces',
        {'per_page': 5},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('get agent categories', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_agent_categories',
        {},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('get workspace categories', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_workspace_categories',
        {},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('resolve non-existent agent returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand(
          'hub_resolve_agent',
          {'agent_id': 'nonexistent-agent-id-xyz'},
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
          {'workspace_id': 'nonexistent-workspace-id-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('hub_popular_tags returns result', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_popular_tags',
        {},
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('hub_search_tags returns result', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'hub_search_tags',
        {'query': 'test'},
      );

      expect(result, isA<Map<String, dynamic>>());
    });
  });
}
