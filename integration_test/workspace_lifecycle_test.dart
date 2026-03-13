// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:io';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _validConfigYaml = '''
name: test-workspace
agents:
  main:
    template: dspatch://agent/test/echo
''';

void main() {
  late TestHarness harness;
  final tempDirs = <Directory>[];

  Directory makeTempDir() {
    final dir = Directory.systemTemp.createTempSync('dspatch_ws_test_');
    tempDirs.add(dir);
    return dir;
  }

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
    for (final dir in tempDirs) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  });

  group('Workspace CRUD (non-Docker)', () {
    test('create workspace returns workspace with ID and name', () async {
      final dir = makeTempDir();
      final result = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );

      expect(result, containsPair('id', isA<String>()));
      expect(result['id'], isNotEmpty);
      expect(result['name'], equals('test-workspace'));

      // Clean up
      await harness.client.deleteWorkspace(result['id'] as String);
    });

    test('get workspace by ID matches created workspace', () async {
      final dir = makeTempDir();
      final created = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );
      final id = created['id'] as String;

      final fetched = await harness.client.sendCommand(
        'get_workspace',
        {'id': id},
      );

      expect(fetched['id'], equals(id));
      expect(fetched['name'], equals(created['name']));

      // Clean up
      await harness.client.deleteWorkspace(id);
    });

    test('delete workspace succeeds', () async {
      final dir = makeTempDir();
      final created = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );
      final id = created['id'] as String;

      final result = await harness.client.deleteWorkspace(id);
      expect(result, isA<Map<String, dynamic>>());
    });

    test('get deleted workspace returns NOT_FOUND', () async {
      final dir = makeTempDir();
      final created = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );
      final id = created['id'] as String;

      await harness.client.deleteWorkspace(id);

      expect(
        () => harness.client.sendCommand('get_workspace', {'id': id}),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            'NOT_FOUND',
          ),
        ),
      );
    });

    test('delete non-existent workspace returns NOT_FOUND', () async {
      expect(
        () => harness.client.deleteWorkspace('non-existent-id'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            'NOT_FOUND',
          ),
        ),
      );
    });

    test('create with invalid YAML returns error', () async {
      final dir = makeTempDir();

      expect(
        () => harness.client.createWorkspace(
          projectPath: dir.path,
          configYaml: '{{{not: valid: yaml:::',
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('create with empty project path returns error', () async {
      expect(
        () => harness.client.createWorkspace(
          projectPath: '',
          configYaml: _validConfigYaml,
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalidation fires on create', () async {
      final dir = makeTempDir();

      // Listen for invalidation events before creating
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('workspaces') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      final created = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'No invalidation received for workspaces table',
        ),
      );

      expect(tables, contains('workspaces'));

      // Clean up
      await sub.cancel();
      await harness.client.deleteWorkspace(created['id'] as String);
    });

    test('Drift read after create', () async {
      final dir = makeTempDir();

      final created = await harness.client.createWorkspace(
        projectPath: dir.path,
        configYaml: _validConfigYaml,
      );
      final id = created['id'] as String;

      // Give the DB a moment to flush (invalidation is debounced)
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final rows =
          await harness.database.select(harness.database.workspaces).get();
      final match = rows.where((w) => w.id == id);
      expect(match, isNotEmpty, reason: 'Created workspace should appear in Drift query');

      // Clean up
      await harness.client.deleteWorkspace(id);
    });
  });
}
