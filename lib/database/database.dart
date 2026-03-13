// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Read-only Drift database backed by the engine's SQLite file.
///
/// Usage:
/// ```dart
/// import 'package:dspatch_app/database/database.dart';
///
/// final db = ref.watch(engineDatabaseProvider);
/// final workspaces = db.select(db.workspaces).watch();
/// ```
library;

export 'engine_database.dart';
