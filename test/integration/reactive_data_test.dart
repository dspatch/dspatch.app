// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:dspatch_app/database/invalidation_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('Reactive data flow', () {
    test('preference set triggers Drift re-query via invalidation', () async {
      final bridge = InvalidationBridge(
        invalidationStream: harness.client.invalidations,
        onInvalidation: harness.database.handleInvalidation,
      );
      bridge.start();

      try {
        final key =
            'reactive_test_${DateTime.now().millisecondsSinceEpoch}';

        final completer = Completer<void>();
        var emissionCount = 0;

        final subscription = harness.database
            .select(harness.database.preferences)
            .watch()
            .listen((_) {
          emissionCount++;
          // First emission is the initial query result,
          // second is the post-invalidation re-query.
          if (emissionCount >= 2 && !completer.isCompleted) {
            completer.complete();
          }
        });

        try {
          await harness.client.setPreference(key, 'reactive_value');
          await completer.future.timeout(const Duration(seconds: 5));
          expect(emissionCount, greaterThanOrEqualTo(2));
        } finally {
          await subscription.cancel();
        }
      } finally {
        bridge.dispose();
      }
    });

    test('provider create triggers invalidation', () async {
      final tables = <String>[];
      final subscription = harness.client.invalidations.listen((event) {
        tables.addAll(event);
      });

      try {
        await harness.client.createAgentProvider(
          request: {
            'name':
                'reactive-test-${DateTime.now().millisecondsSinceEpoch}',
            'sourceType': 'Local',
            'entryPoint': 'main.py',
            'sourcePath': '/tmp/fake-agent',
            'requiredEnv': <String>[],
            'requiredMounts': <String>[],
            'fields': <String, String>{},
            'hubTags': <String>[],
          },
        );

        // Wait for invalidation events to arrive.
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(tables, contains('agent_providers'));
      } finally {
        await subscription.cancel();
      }
    });

    test('batch invalidation: rapid writes produce Drift updates', () async {
      final bridge = InvalidationBridge(
        invalidationStream: harness.client.invalidations,
        onInvalidation: harness.database.handleInvalidation,
      );
      bridge.start();

      try {
        final prefix =
            'batch_test_${DateTime.now().millisecondsSinceEpoch}';

        for (var i = 0; i < 10; i++) {
          await harness.client.setPreference('${prefix}_$i', 'value_$i');
        }

        // Wait for all invalidation events to propagate.
        await Future<void>.delayed(const Duration(seconds: 2));

        final rows =
            await harness.database.select(harness.database.preferences).get();

        var matchCount = 0;
        for (final row in rows) {
          final key = row.key;
          if (key.startsWith(prefix)) {
            matchCount++;
          }
        }

        expect(matchCount, equals(10));
      } finally {
        bridge.dispose();
      }
    });
  });
}
