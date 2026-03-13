// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:io';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Minimal dspatch.agent.yml for creating a test workspace.
const _testConfigYaml = '''
name: integration-test-workspace
source_uri: dspatch://agent/test/echo
''';

void main() {
  late TestHarness harness;
  late bool dockerAvailable;

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
    test('launch workspace creates run', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml,
      );
      final workspaceId = workspace['id'] as String;

      try {
        await harness.client.launchWorkspace(workspaceId);
        await Future<void>.delayed(const Duration(seconds: 3));
        // If we got here without throwing, launch succeeded.
      } finally {
        // Best-effort cleanup
        try {
          await harness.client.stopWorkspace(workspaceId);
        } catch (_) {}
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      }
    });

    test('stop workspace succeeds', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml,
      );
      final workspaceId = workspace['id'] as String;

      try {
        await harness.client.launchWorkspace(workspaceId);
        await Future<void>.delayed(const Duration(seconds: 3));

        final result = await harness.client.stopWorkspace(workspaceId);
        expect(result, isA<Map<String, dynamic>>());
      } finally {
        try {
          await harness.client.stopWorkspace(workspaceId);
        } catch (_) {}
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      }
    });

    test('stop already-stopped workspace is idempotent or returns specific error', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml,
      );
      final workspaceId = workspace['id'] as String;

      try {
        await harness.client.launchWorkspace(workspaceId);
        await Future<void>.delayed(const Duration(seconds: 3));
        await harness.client.stopWorkspace(workspaceId);

        // Second stop: should either succeed (idempotent) or throw a
        // specific EngineException.
        try {
          await harness.client.stopWorkspace(workspaceId);
          // Idempotent — no error, that's fine.
        } on EngineException catch (e) {
          expect(e.code, isNotEmpty);
        }
      } finally {
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      }
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

    test('delete non-active runs', () async {
      if (!dockerAvailable) {
        markTestSkipped('Docker not available');
        return;
      }

      final projectDir = createTempProjectDir();
      final workspace = await harness.client.createWorkspace(
        projectPath: projectDir.path,
        configYaml: _testConfigYaml,
      );
      final workspaceId = workspace['id'] as String;

      try {
        await harness.client.launchWorkspace(workspaceId);
        await Future<void>.delayed(const Duration(seconds: 3));
        await harness.client.stopWorkspace(workspaceId);

        final result = await harness.client.deleteNonActiveRuns(
          workspaceId: workspaceId,
        );
        expect(result, isA<Map<String, dynamic>>());
      } finally {
        try {
          await harness.client.deleteWorkspace(workspaceId);
        } catch (_) {}
      }
    });
  });
}
