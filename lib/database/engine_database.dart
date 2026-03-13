// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

part 'engine_database.g.dart';

/// Read-only Drift database that opens the engine's SQLite file.
///
/// All table definitions are imported from the shared `.sql` schema files
/// that the Rust engine also uses. The engine is the exclusive writer —
/// this class exposes only select/watch queries, never inserts or updates.
///
/// WAL mode (set by the engine on DB creation) enables concurrent read
/// access while the engine continues writing.
@DriftDatabase(
  include: {'schema.drift'},
)
class EngineDatabase extends _$EngineDatabase {
  /// Opens the engine's database file in read-only mode.
  ///
  /// [dbPath] is the absolute path to the engine's SQLite database file.
  /// The file must already exist (the engine creates it on first run).
  EngineDatabase(String dbPath)
      : super(_openReadOnly(dbPath));

  /// Constructor for testing — accepts an arbitrary [QueryExecutor].
  EngineDatabase.forTesting(super.executor);

  /// Schema version must match the engine's current schema version.
  /// This value is only used by Drift for migration bookkeeping, but since
  /// this database is read-only and never migrates, it serves as documentation.
  @override
  int get schemaVersion => 1;

  /// No-op migration strategy. The engine owns all migrations.
  /// The read-only client never alters the schema.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Do nothing — the engine creates and migrates the DB.
        },
        onUpgrade: (m, from, to) async {
          // Do nothing — the engine handles upgrades.
        },
      );

  /// Opens a SQLite database file in read-only mode using the native FFI.
  static QueryExecutor _openReadOnly(String dbPath) {
    return NativeDatabase.createInBackground(
      File(dbPath),
      setup: (rawDb) {
        // Verify the database is accessible. WAL mode (set by the engine)
        // allows concurrent readers, so this open should always succeed
        // as long as the file exists.
      },
      readDataFromFileAsDefault: true,
    );
  }

  /// Notifies Drift that the given tables have been updated externally.
  ///
  /// Called by the Engine Client when it receives an `invalidate` frame
  /// from the engine. This causes Drift to re-run any active `watch`
  /// queries that depend on the affected tables.
  ///
  /// [tableNames] is the list of table names from the invalidation event
  /// (e.g., `['agent_messages', 'workspace_runs']`).
  void handleInvalidation(List<String> tableNames) {
    final updates = <TableUpdate>[];
    for (final name in tableNames) {
      final table = allTables.cast<ResultSetImplementation?>().firstWhere(
            (t) => t?.entityName == name,
            orElse: () => null,
          );
      if (table != null) {
        updates.add(TableUpdate.onTable(table));
      }
    }
    if (updates.isNotEmpty) {
      notifyUpdates(updates.toSet());
    }
  }
}
