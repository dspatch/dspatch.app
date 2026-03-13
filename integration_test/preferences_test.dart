// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

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

  group('Preferences CRUD', () {
    test('set and get preference', () async {
      await harness.client.setPreference('test_theme', 'dark');
      final result = await harness.client.getPreference('test_theme');
      expect(result['value'], equals('dark'));
    });

    test('update preference', () async {
      await harness.client.setPreference('test_update', 'first');
      await harness.client.setPreference('test_update', 'second');
      final result = await harness.client.getPreference('test_update');
      expect(result['value'], equals('second'));
    });

    test('get non-existent preference', () async {
      final result = await harness.client.getPreference('nonexistent_key_xyz');
      expect(result['value'], isNull);
    });

    test('delete preference', () async {
      await harness.client.setPreference('test_delete', 'to_remove');
      await harness.client
          .sendCommand('delete_preference', {'key': 'test_delete'});
      final result = await harness.client.getPreference('test_delete');
      expect(result['value'], isNull);
    });

    test('empty key is rejected', () async {
      expect(
        () => harness.client.setPreference('', 'value'),
        throwsA(isA<EngineException>()),
      );
    });

    test('large value (10KB)', () async {
      final largeValue = 'x' * 10240;
      await harness.client.setPreference('test_large', largeValue);
      final result = await harness.client.getPreference('test_large');
      expect(result['value'], equals(largeValue));
    });

    test('many preferences (50)', () async {
      for (var i = 0; i < 50; i++) {
        await harness.client.setPreference('test_many_$i', 'value_$i');
      }
      for (var i = 0; i < 50; i++) {
        final result = await harness.client.getPreference('test_many_$i');
        expect(result['value'], equals('value_$i'));
      }
    });

    test('rapid overwrite', () async {
      for (var i = 0; i < 10; i++) {
        await harness.client.setPreference('test_rapid', 'v$i');
      }
      final result = await harness.client.getPreference('test_rapid');
      expect(result['value'], equals('v9'));
    });
  });
}
