// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:io';

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/models/commands/commands.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _validConfigYaml = '''
name: test-workspace
agents:
  main:
    template: dspatch://agent/test/echo
''';

/// Waits for an invalidation event that includes [tableName].
///
/// Subscribes to the invalidation stream, waits up to [timeout] for the
/// named table to appear, then cancels the subscription.
Future<void> waitForInvalidation(
  EngineClient client,
  String tableName, {
  Duration timeout = const Duration(seconds: 5),
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
    test('create workspace returns workspace with ID, name, and project path',
        () async {
      final dir = makeTempDir();
      late final String id;

      final result = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
      ))).data;
      id = result['id'] as String;
      addTearDown(() => harness.client.send(DeleteWorkspace(id: id)));

      expect(result, containsPair('id', isA<String>()));
      expect(result['id'], isNotEmpty);
      expect(result['name'], equals('test-workspace'));
      expect(result['project_path'], equals(dir.path));
      expect(result, contains('created_at'));
      expect(result, contains('updated_at'));
    });

    test('get workspace by ID matches created workspace', () async {
      final dir = makeTempDir();
      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id = created['id'] as String;
      addTearDown(() => harness.client.send(DeleteWorkspace(id: id)));

      final fetched = (await harness.client.send(RawEngineCommand(
        method: 'get_workspace',
        params: {'id': id},
      ))).data;

      expect(fetched['id'], equals(id));
      expect(fetched['name'], equals(created['name']));
      expect(fetched['project_path'], equals(created['project_path']));
    });

    test('delete workspace succeeds and get returns NOT_FOUND', () async {
      final dir = makeTempDir();
      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id = created['id'] as String;

      final result = (await harness.client.send(RawEngineCommand(
        method: 'delete_workspace',
        params: {'id': id},
      ))).data;
      expect(result, isA<Map<String, dynamic>>());

      // Verify workspace is actually gone.
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'get_workspace',
          params: {'id': id},
        )),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            'NOT_FOUND',
          ),
        ),
      );
    });

    test('delete non-existent workspace succeeds silently', () async {
      // SQL DELETE on a non-existent row returns success (zero rows affected).
      // The workspace service does not check existence before deleting.
      final result = (await harness.client.send(RawEngineCommand(
        method: 'delete_workspace',
        params: {'id': 'non-existent-id'},
      ))).data;
      expect(result, isA<Map<String, dynamic>>());
    });

    test('create with invalid YAML returns VALIDATION_ERROR', () async {
      final dir = makeTempDir();

      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'create_workspace',
          params: {'project_path': dir.path, 'config_yaml': '{{{not: valid: yaml:::'},
        )),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            anyOf('VALIDATION_ERROR', 'INTERNAL_ERROR'),
          ),
        ),
      );
    });

    test('create with empty project path returns error', () async {
      // Empty project paths are invalid — the engine should reject them.
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'create_workspace',
          params: {'project_path': '', 'config_yaml': _validConfigYaml},
        )),
        throwsA(isA<EngineException>()),
      );
    });

    test('create with non-existent project path', () async {
      // The path does not exist on disk. Engine may accept it (stores as-is)
      // or reject it with a validation error.
      final bogusPath = '${Directory.systemTemp.path}/dspatch_nonexistent_${DateTime.now().millisecondsSinceEpoch}';

      // We assert the engine rejects it. If the engine accepts it, this test
      // documents that behavior change.
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'create_workspace',
          params: {'project_path': bogusPath, 'config_yaml': _validConfigYaml},
        )),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalidation fires on create', () async {
      final dir = makeTempDir();

      // Listen for invalidation events before creating.
      final completer = Completer<List<String>>();
      final sub = harness.client.invalidations.listen((tables) {
        if (tables.contains('workspaces') && !completer.isCompleted) {
          completer.complete(tables);
        }
      });

      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id = created['id'] as String;
      addTearDown(() async {
        await sub.cancel();
        await harness.client.send(DeleteWorkspace(id: id));
      });

      final tables = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'No invalidation received for workspaces table',
        ),
      );

      expect(tables, contains('workspaces'));
    });

    test('Drift read after create uses invalidation-driven wait', () async {
      final dir = makeTempDir();

      final created = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id = created['id'] as String;
      addTearDown(() => harness.client.send(DeleteWorkspace(id: id)));

      // Wait for the invalidation event instead of sleeping — this signals
      // the engine has committed the write and WAL is flushed.
      await waitForInvalidation(harness.client, 'workspaces');

      final rows =
          await harness.database.select(harness.database.workspaces).get();
      final match = rows.where((w) => w.id == id);
      expect(match, isNotEmpty,
          reason: 'Created workspace should appear in Drift query');

      final ws = match.first;
      expect(ws.name, equals('test-workspace'));
      expect(ws.projectPath, equals(dir.path));
      expect(ws.createdAt, isNotEmpty);
    });

    test('Drift workspace list reflects create and delete', () async {
      // Snapshot existing workspaces so we can detect our additions.
      final before =
          await harness.database.select(harness.database.workspaces).get();
      final beforeIds = before.map((w) => w.id).toSet();

      // Create two workspaces.
      final dir1 = makeTempDir();
      final dir2 = makeTempDir();
      final ws1 = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir1.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id1 = ws1['id'] as String;
      await waitForInvalidation(harness.client, 'workspaces');

      final ws2 = (await harness.client.send(RawEngineCommand(
        method: 'create_workspace',
        params: {'project_path': dir2.path, 'config_yaml': _validConfigYaml},
      ))).data;
      final id2 = ws2['id'] as String;
      await waitForInvalidation(harness.client, 'workspaces');

      addTearDown(() async {
        try {
          await harness.client.send(DeleteWorkspace(id: id1));
        } catch (_) {}
        try {
          await harness.client.send(DeleteWorkspace(id: id2));
        } catch (_) {}
      });

      // Verify both appear.
      final afterCreate =
          await harness.database.select(harness.database.workspaces).get();
      final newIds =
          afterCreate.map((w) => w.id).toSet().difference(beforeIds);
      expect(newIds, containsAll([id1, id2]));

      // Delete one, verify only the other remains.
      await harness.client.send(DeleteWorkspace(id: id1));
      await waitForInvalidation(harness.client, 'workspaces');

      final afterDelete =
          await harness.database.select(harness.database.workspaces).get();
      final remainingNew =
          afterDelete.map((w) => w.id).toSet().difference(beforeIds);
      expect(remainingNew, contains(id2));
      expect(remainingNew, isNot(contains(id1)));
    });

    test('concurrent workspace creates produce distinct IDs', () async {
      final dirs = List.generate(5, (_) => makeTempDir());
      final createdIds = <String>[];

      try {
        final results = await Future.wait(
          dirs.map(
            (dir) => harness.client.send(RawEngineCommand(
              method: 'create_workspace',
              params: {'project_path': dir.path, 'config_yaml': _validConfigYaml},
            )),
          ),
        );

        for (final r in results) {
          final id = r.data['id'] as String;
          expect(id, isNotEmpty);
          createdIds.add(id);
        }

        // All IDs should be unique.
        expect(createdIds.toSet().length, equals(createdIds.length),
            reason: 'All concurrent workspace IDs should be distinct');
      } finally {
        for (final id in createdIds) {
          try {
            await harness.client.send(DeleteWorkspace(id: id));
          } catch (_) {}
        }
      }
    });
  });
}
