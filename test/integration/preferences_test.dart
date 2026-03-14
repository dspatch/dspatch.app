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

  group('Preferences CRUD', () {
    test('set preference succeeds', () async {
      // set_preference returns null data -> empty map.
      final result = await harness.client.setPreference('test_theme', 'dark');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('get non-existent preference returns empty map', () async {
      // get_preference for a missing key returns Value::Null on the engine
      // side, which maps to an empty map on the Dart side.
      final result = await harness.client.getPreference('nonexistent_key_xyz');
      expect(result, isEmpty);
    });

    test('delete preference succeeds', () async {
      await harness.client.setPreference('test_delete', 'to_remove');
      final result = await harness.client.sendCommand(
        'delete_preference',
        {'key': 'test_delete'},
      );
      // delete_preference returns null data -> empty map.
      expect(result, isA<Map<String, dynamic>>());

      // After delete, get returns empty map (key no longer exists).
      final after = await harness.client.getPreference('test_delete');
      expect(after, isEmpty);
    });

    test('empty key is rejected', () async {
      expect(
        () => harness.client.setPreference('', 'value'),
        throwsA(isA<EngineException>()),
      );
    });

    test('overwrite preference does not error', () async {
      await harness.client.setPreference('test_overwrite', 'first');
      final result =
          await harness.client.setPreference('test_overwrite', 'second');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('many preferences (50) all set without error', () async {
      for (var i = 0; i < 50; i++) {
        await harness.client.setPreference('test_many_$i', 'value_$i');
      }
    });

    test('rapid overwrite succeeds', () async {
      for (var i = 0; i < 10; i++) {
        await harness.client.setPreference('test_rapid', 'v$i');
      }
      // If we get here without errors, rapid overwrites work.
    });
  });
}
