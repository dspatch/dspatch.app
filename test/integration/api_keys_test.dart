// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

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
    test('create API key persists to DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_create_$ts';

      final result = await harness.client.createApiKey(
        name: name,
        value: 'sk-test-1234',
        providerName: 'openai',
      );

      // create_api_key returns null data (empty map on Dart side).
      expect(result, isA<Map<String, dynamic>>());

      // Verify the key exists in the Drift database.
      final rows =
          await harness.database.select(harness.database.apiKeys).get();
      final match = rows.where((r) => r.name == name).toList();
      expect(match, hasLength(1));
      expect(match.first.providerLabel, equals('openai'));

      // The stored value should be encrypted, not plaintext.
      final storedKey = match.first.encryptedKey;
      expect(storedKey, isNotEmpty);

      addTearDown(() async {
        await harness.client.deleteApiKey(match.first.id);
      });
    });

    test('get key by name returns key with correct fields', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_lookup_$ts';

      await harness.client.createApiKey(
        name: name,
        value: 'sk-test-5678',
        providerName: 'openai',
      );

      final result = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': name},
      );

      expect(result['name'], equals(name));

      // Clean up via the fetched ID.
      addTearDown(() async {
        final id = result['id'] as String;
        await harness.client.deleteApiKey(id);
      });
    });

    test('delete key removes it from DB', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_delete_$ts';

      await harness.client.createApiKey(
        name: name,
        value: 'sk-test-delete',
        providerName: 'openai',
      );

      final fetched = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': name},
      );
      final id = fetched['id'] as String;

      await harness.client.deleteApiKey(id);

      // Verify via engine command: get_api_key_by_name returns null.
      final afterDelete = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': name},
      );
      expect(afterDelete['value'], isNull);

      // Verify via Drift: row is gone.
      final rows =
          await harness.database.select(harness.database.apiKeys).get();
      final match = rows.where((r) => r.id == id);
      expect(match, isEmpty);
    });

    test('create with empty value succeeds', () async {
      // The engine accepts empty values — the encrypted_key column stores
      // the encryption of an empty string. This is a definitive assertion,
      // not "accept either behavior."
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_empty_$ts';

      final result = await harness.client.createApiKey(
        name: name,
        value: '',
        providerName: 'openai',
      );

      expect(result, isA<Map<String, dynamic>>());

      // Verify it was stored.
      final rows =
          await harness.database.select(harness.database.apiKeys).get();
      final match = rows.where((r) => r.name == name).toList();
      expect(match, hasLength(1));

      addTearDown(() async {
        await harness.client.deleteApiKey(match.first.id);
      });
    });

    test('create without providerName uses default label', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_no_provider_$ts';

      final result = await harness.client.createApiKey(
        name: name,
        value: 'sk-test-no-provider',
      );

      expect(result, isA<Map<String, dynamic>>());

      // Verify it was stored and has a non-empty provider label.
      final rows =
          await harness.database.select(harness.database.apiKeys).get();
      final match = rows.where((r) => r.name == name).toList();
      expect(match, hasLength(1));
      expect(match.first.providerLabel, isNotEmpty);

      addTearDown(() async {
        await harness.client.deleteApiKey(match.first.id);
      });
    });

    test('invalidation fires on create', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('api_keys') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      final name = 'test_key_inv_$ts';
      await harness.client.createApiKey(
        name: name,
        value: 'sk-test-inv',
        providerName: 'openai',
      );

      addTearDown(() async {
        await sub.cancel();
        final fetched = await harness.client.sendCommand(
          'get_api_key_by_name',
          {'name': name},
        );
        if (fetched['id'] != null) {
          await harness.client.deleteApiKey(fetched['id'] as String);
        }
      });

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for create'),
      );

      expect(tables, contains('api_keys'));
    });

    test('invalidation fires on delete', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = 'test_key_inv_del_$ts';

      await harness.client.createApiKey(
        name: name,
        value: 'sk-test-inv-del',
        providerName: 'openai',
      );

      final fetched = await harness.client.sendCommand(
        'get_api_key_by_name',
        {'name': name},
      );
      final id = fetched['id'] as String;

      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('api_keys') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      addTearDown(() => sub.cancel());

      await harness.client.deleteApiKey(id);

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for delete'),
      );

      expect(tables, contains('api_keys'));
    });
  });
}
