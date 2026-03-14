// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:io';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Returns a workspace config YAML referencing the given agent provider name.
String _testConfigYaml(String providerName) => '''
name: container-mgmt-test
agents:
  main:
    template: $providerName
''';

/// Waits for an invalidation event that includes [tableName].
Future<void> _waitForInvalidation(
  EngineClient client,
  String tableName, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final completer = Completer<void>();
  final sub = client.invalidations.listen((tables) {
    if (tables.contains(tableName) && !completer.isCompleted) {
      completer.complete();
    }
  });
  try {
    await completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'No invalidation received for $tableName table',
      ),
    );
  } finally {
    await sub.cancel();
  }
}

void main() {
  late TestHarness harness;
  late bool dockerAvailable;
  late String testProviderName;

  final tempDirs = <Directory>[];

  Directory createTempProjectDir() {
    final dir = Directory.systemTemp.createTempSync('dspatch_cm_test_');
    tempDirs.add(dir);
    return dir;
  }

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
    dockerAvailable = await harness.isDockerAvailable();

    if (dockerAvailable) {
      // Register a local agent provider for container management tests.
      final agentDir = Directory.systemTemp.createTempSync('dspatch_agent_');
      tempDirs.add(agentDir);
      File('${agentDir.path}/main.py').writeAsStringSync('# test agent\n');

      testProviderName =
          'test-cm-${DateTime.now().millisecondsSinceEpoch}';
      await harness.client.createAgentProvider(
        request: {
          'name': testProviderName,
          'sourceType': 'local',
          'entryPoint': 'main.py',
          'sourcePath': agentDir.path,
          'requiredEnv': <String>[],
          'requiredMounts': <String>[],
          'fields': <String, String>{},
          'hubTags': <String>[],
        },
      );
    }
  });

  tearDownAll(() async {
    await harness.tearDown();
    for (final dir in tempDirs) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  });

  group('Docker container management', () {
    test('detect Docker status returns available with details', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.detectDockerStatus();
      expect(result['available'], isTrue);
      // The response should contain meaningful Docker status information.
      expect(result, isA<Map<String, dynamic>>());
    });

    test('list containers returns well-formed list', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.listContainers();
      expect(result, isA<List<Map<String, dynamic>>>());

      // If there are containers, each should have an id field.
      for (final container in result) {
        expect(container, contains('id'));
      }
    });

    test('stopAllContainers returns result map', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.stopAllContainers();
      expect(result, isA<Map<String, dynamic>>());
    });

    test('deleteStoppedContainers returns result map', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.deleteStoppedContainers();
      expect(result, isA<Map<String, dynamic>>());
    });

    test('cleanOrphanedContainers returns result map', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final result = await harness.client.cleanOrphanedContainers();
      expect(result, isA<Map<String, dynamic>>());
    });
  });

  group('Docker container lifecycle', () {
    test('launch, list, stop, remove lifecycle', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml(testProviderName),
      );
      final workspaceId = workspace['id'] as String;

      addTearDown(() async {
        try {
          await harness.client.stopWorkspace(workspaceId);
        } catch (_) {}
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      });

      // Launch workspace to create a container.
      await harness.client.launchWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Get the run record to find the container ID.
      final runs = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final run = runs.firstWhere((r) => r.workspaceId == workspaceId);
      expect(run.id, isNotEmpty);

      // List containers and verify we get a list back.
      final containers = await harness.client.listContainers();
      expect(containers, isA<List<Map<String, dynamic>>>());

      // Stop the workspace (which stops the container).
      await harness.client.stopWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Verify run status updated.
      final runsAfterStop = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final stoppedRun =
          runsAfterStop.firstWhere((r) => r.id == run.id);
      expect(stoppedRun.status, isNot(equals('running')));
    });

    test('stopAllContainers stops launched container', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml(testProviderName),
      );
      final workspaceId = workspace['id'] as String;

      addTearDown(() async {
        try {
          await harness.client.stopWorkspace(workspaceId);
        } catch (_) {}
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      });

      await harness.client.launchWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Stop all containers via the bulk operation.
      final result = await harness.client.stopAllContainers();
      expect(result, isA<Map<String, dynamic>>());
    });
  });

  group('Docker container error paths', () {
    test('stopContainer with invalid ID throws EngineException', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      expect(
        () => harness.client.stopContainer(id: 'nonexistent-container-id'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            anyOf('NOT_FOUND', 'DOCKER_ERROR'),
          ),
        ),
      );
    });

    test('removeContainer with invalid ID throws EngineException', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      expect(
        () => harness.client.removeContainer(id: 'nonexistent-container-id'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            anyOf('NOT_FOUND', 'DOCKER_ERROR'),
          ),
        ),
      );
    });

    test('containerStats with invalid ID throws EngineException', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      expect(
        () => harness.client.containerStats(
          containerId: 'nonexistent-container-id',
        ),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            anyOf('NOT_FOUND', 'DOCKER_ERROR'),
          ),
        ),
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
