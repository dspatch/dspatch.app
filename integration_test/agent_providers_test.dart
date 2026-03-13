// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

Map<String, dynamic> validProviderRequest({String? name}) => {
      'name': name ?? 'test-provider-${DateTime.now().millisecondsSinceEpoch}',
      'source_type': 'local',
      'entry_point': 'main.py',
      'source_path': '/tmp/fake-agent',
      'required_env': <String>[],
      'required_mounts': <String>[],
      'fields': <String, String>{},
      'hub_tags': <String>[],
    };

void main() {
  final harness = TestHarness.fromEnv();

  setUp(() => harness.setUp());
  tearDown(() => harness.tearDown());

  group('Agent Providers CRUD', () {
    test('create returns provider with ID', () async {
      final result = await harness.client.createAgentProvider(
        request: validProviderRequest(),
      );

      expect(result, contains('id'));
      expect(result['id'], isA<String>());
      expect((result['id'] as String).isNotEmpty, isTrue);
    });

    test('get returns created provider', () async {
      final created = await harness.client.createAgentProvider(
        request: validProviderRequest(name: 'get-test'),
      );
      final id = created['id'] as String;

      final fetched = await harness.client.sendCommand(
        'get_agent_provider',
        {'id': id},
      );

      expect(fetched['id'], equals(id));
      expect(fetched['name'], equals('get-test'));
    });

    test('update changes fields', () async {
      final created = await harness.client.createAgentProvider(
        request: validProviderRequest(name: 'before-update'),
      );
      final id = created['id'] as String;

      final updated = await harness.client.updateAgentProvider(
        id: id,
        request: validProviderRequest(name: 'after-update'),
      );

      expect(updated['name'], equals('after-update'));
    });

    test('delete succeeds, then get throws NOT_FOUND', () async {
      final created = await harness.client.createAgentProvider(
        request: validProviderRequest(),
      );
      final id = created['id'] as String;

      await harness.client.deleteAgentProvider(id);

      expect(
        () => harness.client.sendCommand('get_agent_provider', {'id': id}),
        throwsA(
          isA<EngineException>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('delete non-existent returns NOT_FOUND', () async {
      expect(
        () => harness.client
            .deleteAgentProvider('00000000-0000-0000-0000-000000000000'),
        throwsA(
          isA<EngineException>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('create with empty request returns VALIDATION error', () async {
      expect(
        () => harness.client.createAgentProvider(
          request: <String, dynamic>{},
        ),
        throwsA(
          isA<EngineException>().having((e) => e.code, 'code', 'VALIDATION'),
        ),
      );
    });

    test('update non-existent returns NOT_FOUND', () async {
      expect(
        () => harness.client.updateAgentProvider(
          id: '00000000-0000-0000-0000-000000000000',
          request: validProviderRequest(),
        ),
        throwsA(
          isA<EngineException>().having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('invalidation fires on create', () async {
      final tablesFuture = harness.client.invalidations.first;

      await harness.client.createAgentProvider(
        request: validProviderRequest(),
      );

      final tables = await tablesFuture;
      expect(tables, contains('agent_providers'));
    });

    test('create multiple, all retrievable by ID', () async {
      final ids = <String>[];

      for (var i = 0; i < 3; i++) {
        final result = await harness.client.createAgentProvider(
          request: validProviderRequest(name: 'multi-$i'),
        );
        ids.add(result['id'] as String);
      }

      for (final id in ids) {
        final fetched = await harness.client.sendCommand(
          'get_agent_provider',
          {'id': id},
        );
        expect(fetched['id'], equals(id));
      }
    });
  });
}
