// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:dspatch_app/engine_client/engine_auth.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Builds a valid create-agent-provider request using camelCase keys
/// (matching the Rust `CreateAgentProviderRequest` with `rename_all = "camelCase"`).
Map<String, dynamic> validProviderRequest({String? name}) => {
      'name': name ?? 'edge-provider-${DateTime.now().millisecondsSinceEpoch}',
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

  group('Unknown and malformed commands', () {
    test('unknown method returns error, engine stays alive', () async {
      expect(
        () => harness.client.sendCommand('totally_fake_method'),
        throwsA(isA<EngineException>()),
      );

      // Engine should still respond after the error.
      final ts = DateTime.now().millisecondsSinceEpoch;
      await harness.client.setPreference('edge_alive_$ts', 'ok');
      final result = await harness.client.getPreference('edge_alive_$ts');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('empty params for command requiring params', () async {
      expect(
        () => harness.client.sendCommand('get_workspace', {}),
        throwsA(isA<EngineException>()),
      );
    });

    test('extra unknown params handled gracefully', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await harness.client.setPreference('edge_extra_$ts', 'hello');

      final result = await harness.client.sendCommand('set_preference', {
        'key': 'edge_extra_$ts',
        'value': 'world',
        'unknown_field': 'ignored',
      });

      expect(result, isA<Map<String, dynamic>>());

      // Verify the value was actually updated.
      final readBack = await harness.client.getPreference('edge_extra_$ts');
      expect(readBack['value'], equals('world'));
    });
  });

  group('Concurrent commands', () {
    test('100 rapid-fire set_preference all persisted', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final futures = <Future<Map<String, dynamic>>>[];
      for (var i = 0; i < 100; i++) {
        futures.add(
          harness.client.setPreference('edge_rapid_${ts}_$i', 'value_$i'),
        );
      }

      await Future.wait(futures);

      // Verify all 100 values persisted via Drift read-back.
      final rows =
          await harness.database.select(harness.database.preferences).get();
      final written =
          rows.where((r) => r.key.startsWith('edge_rapid_${ts}_')).length;
      expect(written, equals(100));
    });

    test('concurrent create and delete on different resources', () async {
      // Create two providers up front so we have distinct IDs.
      final ts = DateTime.now().millisecondsSinceEpoch;
      final created1 = await harness.client.createAgentProvider(
        request: validProviderRequest(name: 'edge-conc-1-$ts'),
      );
      final created2 = await harness.client.createAgentProvider(
        request: validProviderRequest(name: 'edge-conc-2-$ts'),
      );
      final id1 = created1['id'] as String;
      final id2 = created2['id'] as String;

      // Fire a create and two deletes concurrently.
      final results = await Future.wait([
        harness.client.createAgentProvider(
          request: validProviderRequest(name: 'edge-conc-3-$ts'),
        ),
        harness.client.deleteAgentProvider(id1),
        harness.client.deleteAgentProvider(id2),
      ]);

      // The create should have returned a valid id.
      final newId = results[0]['id'] as String;
      expect(newId, isNotEmpty);

      // Verify the deleted providers are gone and the new one exists
      // via Drift read-back.
      final rows = await harness.database
          .select(harness.database.agentProviders)
          .get();
      final ids = rows.map((r) => r.id).toSet();
      expect(ids, isNot(contains(id1)));
      expect(ids, isNot(contains(id2)));
      expect(ids, contains(newId));
    });
  });

  group('Connection resilience', () {
    test('two connections can read each other\'s writes', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;

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
        // Client 1 writes, client 2 reads.
        await harness.client
            .setPreference('edge_conn1_$ts', 'from_client1');
        final read1 = await client2.getPreference('edge_conn1_$ts');
        expect(read1['value'], equals('from_client1'));

        // Client 2 writes, client 1 reads.
        await client2.setPreference('edge_conn2_$ts', 'from_client2');
        final read2 = await harness.client.getPreference('edge_conn2_$ts');
        expect(read2['value'], equals('from_client2'));
      } finally {
        client2.dispose();
      }
    });
  });

  group('Large payloads', () {
    test('1MB preference value round-trips', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final largeValue = 'x' * (1024 * 1024); // 1 MB

      await harness.client.setPreference('edge_1mb_$ts', largeValue);

      // Read back and verify the full value survived.
      final result = await harness.client.getPreference('edge_1mb_$ts');
      expect(result['value'], equals(largeValue));
    });
  });

  group('Invalidation does not block commands', () {
    test('command succeeds while invalidation stream is active', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final completer = Completer<void>();
      var invalidationCount = 0;

      final subscription = harness.client.invalidations.listen((tables) {
        invalidationCount++;
        if (invalidationCount >= 2 && !completer.isCompleted) {
          completer.complete();
        }
      });

      try {
        // Set a preference twice rapidly -- each triggers an invalidation.
        await harness.client
            .setPreference('edge_inval_$ts', 'first');
        await harness.client
            .setPreference('edge_inval_$ts', 'second');

        // Wait for invalidation events to actually arrive.
        await completer.future.timeout(const Duration(seconds: 5));

        expect(invalidationCount, greaterThanOrEqualTo(2));

        // Verify the final value is correct (commands were not blocked).
        final result =
            await harness.client.getPreference('edge_inval_$ts');
        expect(result['value'], equals('second'));
      } finally {
        await subscription.cancel();
      }
    });
  });
}
