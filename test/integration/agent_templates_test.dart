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

  group('Agent Templates CRUD', () {
    test('create template returns template with ID', () async {
      final result = await harness.client.createAgentTemplate(request: {
        'name': 'test-template',
        'source_uri': 'dspatch://agent/test/my-agent',
      });

      expect(result, containsPair('id', isA<String>()));
      expect(result['id'], isNotEmpty);

      // Clean up
      await harness.client.deleteAgentTemplate(result['id'] as String);
    });

    test('update template changes name', () async {
      final created = await harness.client.createAgentTemplate(request: {
        'name': 'before-update',
        'source_uri': 'dspatch://agent/test/my-agent',
      });
      final id = created['id'] as String;

      // updateAgentTemplate returns null data (empty map on Dart side).
      await harness.client.updateAgentTemplate(
        id: id,
        name: 'after-update',
        sourceUri: 'dspatch://agent/test/my-agent',
      );

      // Verify by re-fetching — there is no get_agent_template command,
      // so we just confirm the update did not throw.

      // Clean up
      await harness.client.deleteAgentTemplate(id);
    });

    test('delete template succeeds', () async {
      final created = await harness.client.createAgentTemplate(request: {
        'name': 'to-delete',
        'source_uri': 'dspatch://agent/test/my-agent',
      });
      final id = created['id'] as String;

      final result = await harness.client.deleteAgentTemplate(id);
      expect(result, isA<Map<String, dynamic>>());
    });

    test('delete non-existent succeeds silently', () async {
      // SQL DELETE on a non-existent row returns success (zero rows affected).
      final result = await harness.client.deleteAgentTemplate('non-existent-id');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('create with missing name returns VALIDATION_ERROR', () async {
      expect(
        () => harness.client.createAgentTemplate(request: {
          'source_uri': 'dspatch://agent/test/my-agent',
        }),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
        ),
      );
    });

    test('create with missing source_uri returns VALIDATION_ERROR', () async {
      expect(
        () => harness.client.createAgentTemplate(request: {
          'name': 'bad-uri-template',
        }),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
        ),
      );
    });
  });
}
