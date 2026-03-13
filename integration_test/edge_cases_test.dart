// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

Map<String, dynamic> validProviderRequest({String? name}) => {
      'name': name ?? 'edge-provider-${DateTime.now().millisecondsSinceEpoch}',
      'source_type': 'local',
      'entry_point': 'main.py',
      'source_path': '/tmp/fake-agent',
      'required_env': <String>[],
      'required_mounts': <String>[],
      'fields': <String, String>{},
      'hub_tags': <String>[],
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

  group('Unknown and malformed commands', () {
    test('unknown method returns error, engine stays alive', () async {
      expect(
        () => harness.client.sendCommand('totally_fake_method'),
        throwsA(isA<EngineException>()),
      );

      // Engine should still respond after the error.
      final result = await harness.client.getPreference('nonexistent_check');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('empty params for command requiring params', () async {
      expect(
        () => harness.client.sendCommand('get_workspace', {}),
        throwsA(isA<EngineException>()),
      );
    });

    test('extra unknown params handled gracefully', () async {
      await harness.client.setPreference('edge_extra_param', 'hello');

      final result = await harness.client.sendCommand('get_preference', {
        'key': 'edge_extra_param',
        'unknown_field': 'ignored',
      });

      expect(result['value'], equals('hello'));
    });
  });

  group('Concurrent commands', () {
    test('100 rapid-fire set_preference all complete', () async {
      final futures = <Future<Map<String, dynamic>>>[];
      for (var i = 0; i < 100; i++) {
        futures.add(
          harness.client.setPreference('edge_rapid_$i', 'value_$i'),
        );
      }

      await Future.wait(futures);

      // Verify the last one is readable.
      final result = await harness.client.getPreference('edge_rapid_99');
      expect(result['value'], equals('value_99'));
    });

    test('concurrent create and delete no corruption', () async {
      final created = await harness.client.createAgentProvider(
        request: validProviderRequest(name: 'edge-concurrent-delete'),
      );
      final id = created['id'] as String;

      await harness.client.deleteAgentProvider(id);

      // Second delete should throw since the provider no longer exists.
      expect(
        () => harness.client.deleteAgentProvider(id),
        throwsA(isA<EngineException>()),
      );
    });
  });

  group('Connection resilience', () {
    test('two simultaneous connections work independently', () async {
      // Create a second authenticated connection.
      final auth2 = EngineAuth(host: harness.host, port: harness.port);
      final authResult2 = await auth2.authenticateAnonymous();
      auth2.dispose();

      final connection2 = EngineConnection(
        host: harness.host,
        port: harness.port,
        token: authResult2.sessionToken,
      );
      await connection2.connect();

      final client2 = EngineClient(connection2);

      try {
        // Both clients set preferences.
        await harness.client.setPreference('edge_conn1', 'from_client1');
        await client2.setPreference('edge_conn2', 'from_client2');

        // Both can read each other's data.
        final result1 = await harness.client.getPreference('edge_conn2');
        expect(result1['value'], equals('from_client2'));

        final result2 = await client2.getPreference('edge_conn1');
        expect(result2['value'], equals('from_client1'));
      } finally {
        client2.dispose();
      }
    });
  });

  group('Large payloads', () {
    test('1MB preference value', () async {
      final largeValue = 'x' * (1024 * 1024); // 1 MB

      try {
        await harness.client.setPreference('edge_1mb', largeValue);
        final result = await harness.client.getPreference('edge_1mb');
        expect(result['value'], equals(largeValue));
      } on EngineException {
        // Also acceptable — engine may reject oversized values.
      }
    });
  });

  group('Invalidation does not block commands', () {
    test('command succeeds right after receiving invalidation', () async {
      // Set a preference twice rapidly — the first triggers an invalidation.
      await harness.client.setPreference('edge_inval', 'first');
      await harness.client.setPreference('edge_inval', 'second');

      final result = await harness.client.getPreference('edge_inval');
      expect(result['value'], equals('second'));
    });
  });
}
