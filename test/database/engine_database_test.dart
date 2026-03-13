import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dspatch_app/database/engine_database.dart';

void main() {
  late EngineDatabase db;

  setUp(() {
    // Use an in-memory database for testing.
    db = EngineDatabase.forTesting(
      NativeDatabase.memory(setup: (rawDb) {
        // Enable WAL mode like the engine would.
        rawDb.execute('PRAGMA journal_mode=WAL;');
      }),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('EngineDatabase', () {
    test('opens successfully with in-memory executor', () {
      // If we got here without exceptions, the database opened fine.
      expect(db, isNotNull);
    });

    test('allTables contains expected tables', () {
      final tableNames = db.allTables.map((t) => t.entityName).toSet();

      // Spot-check a few key tables from each category.
      expect(tableNames, contains('workspaces'));
      expect(tableNames, contains('agent_messages'));
      expect(tableNames, contains('workspace_runs'));
      expect(tableNames, contains('agent_providers'));
      expect(tableNames, contains('agent_instance_states'));
      expect(tableNames, contains('recent_projects'));
    });

    test('handleInvalidation triggers stream update', () async {
      // Create the tables in our in-memory DB (since there's no engine to do it).
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS workspaces (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          project_path TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
        )
      ''');

      // Start watching the workspaces table.
      var updateCount = 0;
      final subscription = db.customSelect(
        'SELECT * FROM workspaces',
        readsFrom: {db.workspaces},
      ).watch().listen((_) {
        updateCount++;
      });

      // Wait for the initial query to fire.
      await Future.delayed(const Duration(milliseconds: 50));
      final initialCount = updateCount;

      // Simulate an invalidation event from the engine.
      db.handleInvalidation(['workspaces']);

      // Wait for the watcher to re-query.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(updateCount, greaterThan(initialCount),
          reason: 'handleInvalidation should trigger watch re-query');

      await subscription.cancel();
    });

    test('handleInvalidation ignores unknown table names', () {
      // Should not throw when given table names that don't exist in the schema.
      expect(
        () => db.handleInvalidation(['nonexistent_table']),
        returnsNormally,
      );
    });

    test('handleInvalidation handles empty list', () {
      expect(
        () => db.handleInvalidation([]),
        returnsNormally,
      );
    });

    test('handleInvalidation handles multiple tables', () async {
      // Create tables in memory.
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS workspaces (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          project_path TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
        )
      ''');
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS workspace_runs (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'starting',
          started_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          stopped_at TEXT
        )
      ''');

      var workspacesUpdated = false;
      var runsUpdated = false;

      final sub1 = db.customSelect(
        'SELECT * FROM workspaces',
        readsFrom: {db.workspaces},
      ).watch().listen((_) {
        workspacesUpdated = true;
      });

      final sub2 = db.customSelect(
        'SELECT * FROM workspace_runs',
        readsFrom: {db.workspaceRuns},
      ).watch().listen((_) {
        runsUpdated = true;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Reset after initial query.
      workspacesUpdated = false;
      runsUpdated = false;

      // Invalidate both tables at once.
      db.handleInvalidation(['workspaces', 'workspace_runs']);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(workspacesUpdated, isTrue);
      expect(runsUpdated, isTrue);

      await sub1.cancel();
      await sub2.cancel();
    });
  });
}
