// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

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
    test('create template returns template with ID and persists to DB',
        () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test-template-$ts';
      final sourceUri = 'dspatch://agent/test/my-agent';

      final result = await harness.client.createAgentTemplate(request: {
        'name': name,
        'source_uri': sourceUri,
      });

      addTearDown(
        () => harness.client.deleteAgentTemplate(result['id'] as String),
      );

      expect(result, containsPair('id', isA<String>()));
      expect(result['id'], isNotEmpty);

      // Verify via Drift read-back.
      final rows = await harness.database
          .select(harness.database.agentTemplates)
          .get();
      final row = rows.where((r) => r.id == result['id']).toList();
      expect(row, hasLength(1));
      expect(row.first.name, equals(name));
      expect(row.first.sourceUri, equals(sourceUri));
    });

    test('update template changes name and verifiable via DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sourceUri = 'dspatch://agent/test/my-agent';

      final created = await harness.client.createAgentTemplate(request: {
        'name': 'before-update-$ts',
        'source_uri': sourceUri,
      });
      final id = created['id'] as String;

      addTearDown(() => harness.client.deleteAgentTemplate(id));

      await harness.client.updateAgentTemplate(
        id: id,
        name: 'after-update-$ts',
        sourceUri: sourceUri,
      );

      // Verify the mutation via Drift read-back (the production read path).
      final rows = await harness.database
          .select(harness.database.agentTemplates)
          .get();
      final row = rows.where((r) => r.id == id).toList();
      expect(row, hasLength(1));
      expect(row.first.name, equals('after-update-$ts'));
      expect(row.first.sourceUri, equals(sourceUri));
    });

    test('delete template removes row from DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final created = await harness.client.createAgentTemplate(request: {
        'name': 'to-delete-$ts',
        'source_uri': 'dspatch://agent/test/my-agent',
      });
      final id = created['id'] as String;

      final result = await harness.client.deleteAgentTemplate(id);
      expect(result, isA<Map<String, dynamic>>());

      // Verify the row is gone from the database.
      final rows = await harness.database
          .select(harness.database.agentTemplates)
          .get();
      final match = rows.where((r) => r.id == id);
      expect(match, isEmpty);
    });

    test('delete non-existent returns error', () async {
      expect(
        () => harness.client.deleteAgentTemplate('non-existent-id'),
        throwsA(isA<EngineException>()),
      );
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

    test('update non-existent template returns error', () async {
      expect(
        () => harness.client.updateAgentTemplate(
          id: 'non-existent-id',
          name: 'does-not-matter',
          sourceUri: 'dspatch://agent/test/nope',
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalidation fires on create', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('agent_templates') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      final result = await harness.client.createAgentTemplate(request: {
        'name': 'invalidation-test-$ts',
        'source_uri': 'dspatch://agent/test/inv',
      });

      addTearDown(() async {
        await sub.cancel();
        await harness.client.deleteAgentTemplate(result['id'] as String);
      });

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for create'),
      );

      expect(tables, contains('agent_templates'));
    });

    test('invalidation fires on delete', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final created = await harness.client.createAgentTemplate(request: {
        'name': 'inv-delete-test-$ts',
        'source_uri': 'dspatch://agent/test/inv-del',
      });
      final id = created['id'] as String;

      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('agent_templates') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      addTearDown(() => sub.cancel());

      await harness.client.deleteAgentTemplate(id);

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for delete'),
      );

      expect(tables, contains('agent_templates'));
    });
  });
}
