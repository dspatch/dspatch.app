// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late TestHarness harness;
  late bool dockerAvailable;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
    dockerAvailable = await harness.isDockerAvailable();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Docker container management', () {
    test('detect Docker status', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.detectDockerStatus();
      expect(result['available'], isTrue);
    });

    test('list containers returns list', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.listContainers();
      expect(result, isList);
    });

    test('stop all containers succeeds', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      await expectLater(
        harness.client.stopAllContainers(),
        completes,
      );
    });

    test('delete stopped containers succeeds', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      await expectLater(
        harness.client.deleteStoppedContainers(),
        completes,
      );
    });

    test('clean orphaned containers succeeds', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      await expectLater(
        harness.client.cleanOrphanedContainers(),
        completes,
      );
    });
  });

  group('Docker unavailable', () {
    test('detect status returns available=false', () async {
      if (dockerAvailable) {
        markTestSkipped('Docker is available — skipping unavailable test');
        return;
      }

      final result = await harness.client.detectDockerStatus();
      expect(result['available'], isFalse);
    });
  });
}
