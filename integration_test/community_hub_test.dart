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
        'browse_hub_agents',
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
        'browse_hub_agents',
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
        'browse_hub_workspaces',
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
        'get_hub_agent_categories',
        {},
      );

      expect(result, isA<List>());
    });

    test('get workspace categories', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'get_hub_workspace_categories',
        {},
      );

      expect(result, isA<List>());
    });

    test('get non-existent agent returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand(
          'get_hub_agent',
          {'slug': 'nonexistent-agent-slug-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('get non-existent workspace returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand(
          'get_hub_workspace',
          {'slug': 'nonexistent-workspace-slug-xyz'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('get trending agents', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'get_trending_agents',
        {},
      );

      expect(result, isA<List>());
    });

    test('search tags', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand(
        'search_tags',
        {'q': 'test'},
      );

      expect(result, isA<List>());
    });
  });
}
