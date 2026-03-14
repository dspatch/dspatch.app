// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:flutter_test/flutter_test.dart';

import 'community_hub_test.dart' show hubTest;
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

  group('Template resolution (requires localhost:3000)', () {
    // The resolve-non-existent error tests are covered in
    // community_hub_test.dart. This file focuses on template-specific
    // workflows: update checking and (when seeded data exists) happy-path
    // resolution.

    test('check_for_agent_updates with no local agents succeeds', () async {
      await hubTest(harness, () async {
        final result = await harness.client.sendCommand(
          'check_for_agent_updates',
          {},
        );

        expect(result, isA<Map<String, dynamic>>());
        // The response should indicate there are no updates when no agents
        // are installed locally.
        if (result.containsKey('updates')) {
          expect(result['updates'], isA<List>());
        }
      });
    });

    test('check_for_workspace_updates with no local workspaces succeeds',
        () async {
      await hubTest(harness, () async {
        final result = await harness.client.sendCommand(
          'check_for_workspace_updates',
          {},
        );

        expect(result, isA<Map<String, dynamic>>());
        if (result.containsKey('updates')) {
          expect(result['updates'], isA<List>());
        }
      });
    });

    // TODO: Add happy-path tests when the hub has seeded test agents
    // (e.g. dspatch://agent/test/echo). These should:
    // 1. Resolve a known agent by slug via hubResolveAgent
    // 2. Verify response contains expected fields (name, source_uri, version)
    // 3. Verify the resolved template is persisted in the database
  });
}
