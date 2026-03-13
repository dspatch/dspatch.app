// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:test/test.dart';

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

  group('API Keys CRUD', () {
    test('create API key succeeds', () async {
      final result = await harness.client.createApiKey(
        name: 'test_key_create',
        value: 'sk-test-1234',
        providerName: 'openai',
      );

      expect(result, containsPair('name', 'test_key_create'));
      expect(result, contains('id'));
    });

    test('get key by name returns key', () async {
      await harness.client.createApiKey(
        name: 'test_key_lookup',
        value: 'sk-test-5678',
        providerName: 'openai',
      );

      final result = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': 'test_key_lookup'},
      );

      expect(result['name'], equals('test_key_lookup'));
    });

    test('delete key succeeds', () async {
      final created = await harness.client.createApiKey(
        name: 'test_key_delete',
        value: 'sk-test-delete',
        providerName: 'openai',
      );

      final id = created['id'] as String;
      await harness.client.deleteApiKey(id);

      expect(
        () => harness.client.sendCommand(
          'get_api_key_by_name',
          {'name': 'test_key_delete'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('create with empty value returns error', () async {
      expect(
        () => harness.client.createApiKey(
          name: 'test_key_empty',
          value: '',
          providerName: 'openai',
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalidation fires on create', () async {
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('api_keys')) {
          if (!completer.isCompleted) completer.complete(tables);
        }
      });

      await harness.client.createApiKey(
        name: 'test_key_invalidation',
        value: 'sk-test-inv',
        providerName: 'openai',
      );

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('No invalidation received'),
      );

      expect(tables, contains('api_keys'));
      await sub.cancel();
    });
  });
}
