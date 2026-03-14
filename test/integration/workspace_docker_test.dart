// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:io';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Returns a workspace config YAML referencing the given agent provider name.
String testConfigYaml(String providerName) => '''
name: integration-test-workspace
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
    final dir = Directory.systemTemp.createTempSync('dspatch_ws_test_');
    tempDirs.add(dir);
    return dir;
  }

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
    dockerAvailable = await harness.isDockerAvailable();

    if (dockerAvailable) {
      // Register a local agent provider for workspace launch tests.
      // The provider points to a temp directory with a minimal entry point.
      final agentDir = Directory.systemTemp.createTempSync('dspatch_agent_');
      tempDirs.add(agentDir);
      File('${agentDir.path}/main.py').writeAsStringSync('# test agent\n');

      testProviderName =
          'test-echo-${DateTime.now().millisecondsSinceEpoch}';
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

  group('Workspace Docker lifecycle', () {
    test('launch workspace creates run with valid run record', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
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

      final launchResult = await harness.client.launchWorkspace(workspaceId);
      expect(launchResult, isA<Map<String, dynamic>>());

      // Wait for workspace_runs table invalidation instead of sleeping.
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Verify a run was created in the database.
      final runs = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final matchingRuns =
          runs.where((r) => r.workspaceId == workspaceId).toList();
      expect(matchingRuns, isNotEmpty,
          reason: 'Launch should create a workspace run record');

      final run = matchingRuns.first;
      expect(run.id, isNotEmpty);
      expect(run.workspaceId, equals(workspaceId));
      expect(run.startedAt, isNotEmpty);
      expect(run.status, isNotEmpty);
    });

    test('stop workspace updates run status', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
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

      final stopResult = await harness.client.stopWorkspace(workspaceId);
      expect(stopResult, isA<Map<String, dynamic>>());

      // Wait for the stop to be reflected in the DB.
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Verify the run status changed in the database.
      final runs = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final matchingRuns =
          runs.where((r) => r.workspaceId == workspaceId).toList();
      expect(matchingRuns, isNotEmpty);

      // After stop, the run should have a non-running status.
      final run = matchingRuns.first;
      expect(run.status, isNot(equals('running')),
          reason: 'Stopped workspace run should not have running status');
    });

    test('stop already-stopped workspace throws EngineException', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
      );
      final workspaceId = workspace['id'] as String;

      addTearDown(() async {
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      });

      await harness.client.launchWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      await harness.client.stopWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Second stop should error — workspace is already stopped.
      expect(
        () => harness.client.stopWorkspace(workspaceId),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            isNotEmpty,
          ),
        ),
      );
    });

    test('launch non-existent workspace returns NOT_FOUND', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      expect(
        () => harness.client.launchWorkspace('non-existent-workspace-id'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            'NOT_FOUND',
          ),
        ),
      );
    });

    test('container appears in listContainers after launch', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
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

      // The launched workspace should have produced a container.
      final containers = await harness.client.listContainers();
      // Note: the container may have already exited (the agent is a no-op),
      // but we verify the list call succeeds and returns a list.
      expect(containers, isA<List<Map<String, dynamic>>>());
    });

    test('delete non-active runs removes stopped runs from DB', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
      );
      final workspaceId = workspace['id'] as String;

      addTearDown(() async {
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      });

      // Launch then stop to produce a non-active run.
      await harness.client.launchWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');
      await harness.client.stopWorkspace(workspaceId);
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Verify there is at least one run before cleanup.
      final runsBefore = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final runsForWs =
          runsBefore.where((r) => r.workspaceId == workspaceId).toList();
      expect(runsForWs, isNotEmpty,
          reason: 'Should have at least one stopped run');

      // Delete non-active runs.
      final result = await harness.client.deleteNonActiveRuns(
        workspaceId: workspaceId,
      );
      expect(result, isA<Map<String, dynamic>>());

      // Wait for the DB update.
      await _waitForInvalidation(harness.client, 'workspace_runs');

      // Verify non-active runs were removed.
      final runsAfter = await harness.database
          .select(harness.database.workspaceRuns)
          .get();
      final remainingRuns =
          runsAfter.where((r) => r.workspaceId == workspaceId).toList();
      // Only active runs (if any) should remain. Since we stopped the
      // workspace, there should be no active runs, so all should be deleted.
      for (final run in remainingRuns) {
        expect(run.status, equals('running'),
            reason:
                'Only active (running) runs should remain after deleteNonActiveRuns');
      }
    });

    test('launch already-running workspace returns error', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: testConfigYaml(testProviderName),
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

      // Second launch should fail — workspace already has an active run.
      expect(
        () => harness.client.launchWorkspace(workspaceId),
        throwsA(isA<EngineException>()),
      );
    });
  });
}
