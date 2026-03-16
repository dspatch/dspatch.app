// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/models/commands/commands.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Builds a valid create-agent-provider request using camelCase keys
/// (matching the Rust `CreateAgentProviderRequest` with `rename_all = "camelCase"`).
///
/// Uses a timestamped name by default to avoid cross-run collisions.
/// The `sourcePath` is a fake path — the engine stores it as a string
/// without filesystem validation.
Map<String, dynamic> validProviderRequest({String? name}) => {
      'name': name ??
          'test-provider-${DateTime.now().millisecondsSinceEpoch}',
      'sourceType': 'local',
      'entryPoint': 'main.py',
      'sourcePath': '/tmp/fake-agent',
      'requiredEnv': <String>[],
      'requiredMounts': <String>[],
      'fields': <String, String>{},
      'hubTags': <String>[],
    };

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Agent Providers CRUD', () {
    test('create returns provider with all fields populated', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'create-test-$ts';
      final result = (await harness.client.send(RawEngineCommand(
        method: 'create_agent_provider',
        params: validProviderRequest(name: name),
      )))
          .data;

      addTearDown(
        () => harness.client
            .send(DeleteAgentProvider(id: result['id'] as String)),
      );

      // Verify response fields.
      expect(result['id'], isA<String>());
      expect((result['id'] as String).isNotEmpty, isTrue);
      expect(result['name'], equals(name));
      expect(result['sourceType'], equals('local'));
      expect(result['entryPoint'], equals('main.py'));
      expect(result['sourcePath'], equals('/tmp/fake-agent'));

      // Verify via Drift read-back.
      final rows =
          await harness.database.select(harness.database.agentProviders).get();
      final row = rows.where((r) => r.id == result['id']).toList();
      expect(row, hasLength(1));
      expect(row.first.name, equals(name));
      expect(row.first.sourceType, equals('local'));
      expect(row.first.entryPoint, equals('main.py'));
      expect(row.first.sourcePath, equals('/tmp/fake-agent'));
    });

    test('get returns created provider with correct fields', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'get-test-$ts';
      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_agent_provider',
        params: validProviderRequest(name: name),
      )))
          .data;
      final id = created['id'] as String;

      addTearDown(() => harness.client.send(DeleteAgentProvider(id: id)));

      final fetched = (await harness.client.send(RawEngineCommand(
        method: 'get_agent_provider',
        params: {'id': id},
      )))
          .data;

      expect(fetched['id'], equals(id));
      expect(fetched['name'], equals(name));
      expect(fetched['sourceType'], equals('local'));
      expect(fetched['entryPoint'], equals('main.py'));
      expect(fetched['sourcePath'], equals('/tmp/fake-agent'));
    });

    test('update changes fields and persists to DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_agent_provider',
        params: validProviderRequest(name: 'before-update-$ts'),
      )))
          .data;
      final id = created['id'] as String;

      addTearDown(() => harness.client.send(DeleteAgentProvider(id: id)));

      final updated = (await harness.client.send(RawEngineCommand(
        method: 'update_agent_provider',
        params: {'id': id, ...validProviderRequest(name: 'after-update-$ts')},
      )))
          .data;

      expect(updated['name'], equals('after-update-$ts'));

      // Verify update via Drift read-back.
      final rows =
          await harness.database.select(harness.database.agentProviders).get();
      final row = rows.where((r) => r.id == id).toList();
      expect(row, hasLength(1));
      expect(row.first.name, equals('after-update-$ts'));
    });

    test('delete succeeds, then get throws NOT_FOUND', () async {
      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_agent_provider',
        params: validProviderRequest(),
      )))
          .data;
      final id = created['id'] as String;

      await harness.client.send(DeleteAgentProvider(id: id));

      // Verify via engine command.
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'get_agent_provider',
          params: {'id': id},
        )),
        throwsA(
          isA<EngineException>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );

      // Verify row is gone from database.
      final rows =
          await harness.database.select(harness.database.agentProviders).get();
      final match = rows.where((r) => r.id == id);
      expect(match, isEmpty);
    });

    test('delete non-existent succeeds silently', () async {
      // SQL DELETE on a non-existent row returns success (zero rows affected).
      final result = (await harness.client.send(RawEngineCommand(
        method: 'delete_agent_provider',
        params: {'id': '00000000-0000-0000-0000-000000000000'},
      )))
          .data;
      expect(result, isA<Map<String, dynamic>>());
    });

    test('create with empty request returns VALIDATION_ERROR', () async {
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'create_agent_provider',
          params: <String, dynamic>{},
        )),
        throwsA(
          isA<EngineException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR'),
        ),
      );
    });

    test('update non-existent returns error', () async {
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'update_agent_provider',
          params: {
            'id': '00000000-0000-0000-0000-000000000000',
            ...validProviderRequest(),
          },
        )),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalidation fires on create', () async {
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('agent_providers') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      final result = (await harness.client.send(RawEngineCommand(
        method: 'create_agent_provider',
        params: validProviderRequest(),
      )))
          .data;

      addTearDown(() async {
        await sub.cancel();
        await harness.client
            .send(DeleteAgentProvider(id: result['id'] as String));
      });

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for create'),
      );

      expect(tables, contains('agent_providers'));
    });

    test('create multiple, all retrievable by ID and in DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ids = <String>[];

      for (var i = 0; i < 3; i++) {
        final result = (await harness.client.send(RawEngineCommand(
          method: 'create_agent_provider',
          params: validProviderRequest(name: 'multi-$ts-$i'),
        )))
            .data;
        ids.add(result['id'] as String);
      }

      addTearDown(() async {
        for (final id in ids) {
          await harness.client.send(DeleteAgentProvider(id: id));
        }
      });

      // Verify each is retrievable via engine command.
      for (var i = 0; i < ids.length; i++) {
        final fetched = (await harness.client.send(RawEngineCommand(
          method: 'get_agent_provider',
          params: {'id': ids[i]},
        )))
            .data;
        expect(fetched['id'], equals(ids[i]));
        expect(fetched['name'], equals('multi-$ts-$i'));
      }

      // Verify all are in the Drift database.
      final rows =
          await harness.database.select(harness.database.agentProviders).get();
      for (final id in ids) {
        expect(rows.where((r) => r.id == id), hasLength(1));
      }
    });
  });
}
