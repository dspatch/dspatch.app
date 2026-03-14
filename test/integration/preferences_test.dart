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

  group('Preferences CRUD', () {
    test('set preference persists and is readable via get', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final key = 'test_theme_$ts';

      final result = await harness.client.setPreference(key, 'dark');
      expect(result, isA<Map<String, dynamic>>());

      addTearDown(() => harness.client.sendCommand(
            'delete_preference',
            {'key': key},
          ));

      // Verify via engine command.
      final readBack = await harness.client.getPreference(key);
      expect(readBack['value'], equals('dark'));

      // Verify via Drift database.
      final rows =
          await harness.database.select(harness.database.preferences).get();
      final match = rows.where((r) => r.key == key).toList();
      expect(match, hasLength(1));
      expect(match.first.value, equals('dark'));
    });

    test('get non-existent preference returns null value', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final result =
          await harness.client.getPreference('nonexistent_key_$ts');
      expect(result['value'], isNull);
    });

    test('delete preference removes it', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final key = 'test_delete_$ts';

      await harness.client.setPreference(key, 'to_remove');
      final result = await harness.client.sendCommand(
        'delete_preference',
        {'key': key},
      );
      expect(result, isA<Map<String, dynamic>>());

      // Verify via engine command.
      final after = await harness.client.getPreference(key);
      expect(after['value'], isNull);

      // Verify via Drift database.
      final rows =
          await harness.database.select(harness.database.preferences).get();
      final match = rows.where((r) => r.key == key);
      expect(match, isEmpty);
    });

    test('overwrite preference updates to new value', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final key = 'test_overwrite_$ts';

      await harness.client.setPreference(key, 'first');
      await harness.client.setPreference(key, 'second');

      addTearDown(() => harness.client.sendCommand(
            'delete_preference',
            {'key': key},
          ));

      // Verify the final value via engine command.
      final readBack = await harness.client.getPreference(key);
      expect(readBack['value'], equals('second'));

      // Verify via Drift database.
      final rows =
          await harness.database.select(harness.database.preferences).get();
      final match = rows.where((r) => r.key == key).toList();
      expect(match, hasLength(1));
      expect(match.first.value, equals('second'));
    });

    test('many preferences (50) all persisted and retrievable', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final keys = <String>[];

      for (var i = 0; i < 50; i++) {
        final key = 'test_many_${ts}_$i';
        keys.add(key);
        await harness.client.setPreference(key, 'value_$i');
      }

      addTearDown(() async {
        for (final key in keys) {
          await harness.client.sendCommand('delete_preference', {'key': key});
        }
      });

      // Spot-check first, middle, and last values.
      final first = await harness.client.getPreference(keys.first);
      expect(first['value'], equals('value_0'));

      final middle = await harness.client.getPreference(keys[25]);
      expect(middle['value'], equals('value_25'));

      final last = await harness.client.getPreference(keys.last);
      expect(last['value'], equals('value_49'));
    });

    test('rapid overwrite converges to final value', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final key = 'test_rapid_$ts';

      for (var i = 0; i < 10; i++) {
        await harness.client.setPreference(key, 'v$i');
      }

      addTearDown(() => harness.client.sendCommand(
            'delete_preference',
            {'key': key},
          ));

      // Verify the final value is the last one written.
      final readBack = await harness.client.getPreference(key);
      expect(readBack['value'], equals('v9'));
    });

    test('invalidation fires on set', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final key = 'test_inv_$ts';

      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('preferences') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      await harness.client.setPreference(key, 'inv_value');

      addTearDown(() async {
        await sub.cancel();
        await harness.client.sendCommand('delete_preference', {'key': key});
      });

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('No invalidation received for set'),
      );

      expect(tables, contains('preferences'));
    });

    test('set with missing value parameter returns error', () async {
      expect(
        () => harness.client.sendCommand(
          'set_preference',
          {'key': 'test_missing_value'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('get with missing key parameter returns error', () async {
      expect(
        () => harness.client.sendCommand('get_preference', {}),
        throwsA(isA<EngineException>()),
      );
    });
  });
}
