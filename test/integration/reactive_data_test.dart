// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:dspatch_app/database/invalidation_bridge.dart';
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
      final completer = Completer<List<String>>();
      final tables = <String>[];
      final subscription = harness.client.invalidations.listen((event) {
        tables.addAll(event);
        if (tables.contains('agent_providers') && !completer.isCompleted) {
          completer.complete(List.of(tables));
        }
      });

      try {
        await harness.client.createAgentProvider(
          request: {
            'name':
                'reactive-test-${DateTime.now().millisecondsSinceEpoch}',
            'sourceType': 'local',
            'entryPoint': 'main.py',
            'sourcePath': '/tmp/fake-agent',
            'requiredEnv': <String>[],
            'requiredMounts': <String>[],
            'fields': <String, String>{},
            'hubTags': <String>[],
          },
        );

        // Wait for the invalidation event with a timeout instead of
        // a fixed delay -- eliminates the race condition.
        await completer.future.timeout(const Duration(seconds: 5));

        expect(tables, contains('agent_providers'));
      } finally {
        await subscription.cancel();
      }
    });

    test('batch invalidation: rapid writes produce Drift watch updates',
        () async {
      final bridge = InvalidationBridge(
        invalidationStream: harness.client.invalidations,
        onInvalidation: harness.database.handleInvalidation,
      );
      bridge.start();

      try {
        final prefix =
            'batch_test_${DateTime.now().millisecondsSinceEpoch}';

        // Subscribe a watch() query BEFORE writing so we actually test
        // that Drift reactivity fires after invalidation.
        final watchCompleter = Completer<void>();
        var lastMatchCount = 0;

        final subscription = harness.database
            .select(harness.database.preferences)
            .watch()
            .listen((rows) {
          var count = 0;
          for (final row in rows) {
            if (row.key.startsWith(prefix)) {
              count++;
            }
          }
          lastMatchCount = count;
          // Complete once all 10 preferences are visible via the watch.
          if (count >= 10 && !watchCompleter.isCompleted) {
            watchCompleter.complete();
          }
        });

        try {
          for (var i = 0; i < 10; i++) {
            await harness.client.setPreference('${prefix}_$i', 'value_$i');
          }

          // Wait for the watch query to reflect all 10 written values.
          await watchCompleter.future.timeout(const Duration(seconds: 10));

          expect(lastMatchCount, equals(10));
        } finally {
          await subscription.cancel();
        }
      } finally {
        bridge.dispose();
      }
    });
  });
}
