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

  group('API Keys CRUD', () {
    test('create API key succeeds', () async {
      // create_api_key returns null data (empty map on Dart side).
      final result = await harness.client.createApiKey(
        name: 'test_key_create',
        value: 'sk-test-1234',
        providerName: 'openai',
      );

      // The engine returns null (no data), which maps to an empty map.
      expect(result, isA<Map<String, dynamic>>());
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

      // ApiKey model uses camelCase serialization.
      expect(result['name'], equals('test_key_lookup'));
    });

    test('delete key succeeds', () async {
      // First create a key, then look it up to get its ID.
      await harness.client.createApiKey(
        name: 'test_key_delete',
        value: 'sk-test-delete',
        providerName: 'openai',
      );

      final fetched = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': 'test_key_delete'},
      );
      final id = fetched['id'] as String;

      await harness.client.deleteApiKey(id);

      // After deletion, get_api_key_by_name returns None -> null -> empty map.
      final afterDelete = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': 'test_key_delete'},
      );
      // None serializes to null, which on Dart side becomes an empty map.
      expect(afterDelete, isEmpty);
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
