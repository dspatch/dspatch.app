// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for database lifecycle (migration, state queries).
library;

import '../engine_responses.dart';
import 'command.dart';

class GetDatabaseState extends EngineCommand<DatabaseStateResponse> {
  @override
  String get method => 'get_database_state';

  @override
  Map<String, dynamic>? get params => null;

  @override
  DatabaseStateResponse parseResponse(Map<String, dynamic> result) =>
      DatabaseStateResponse.fromJson(result);
}

class PerformMigration extends VoidEngineCommand {
  @override
  String get method => 'perform_migration';

  @override
  Map<String, dynamic>? get params => null;
}

class SkipMigration extends VoidEngineCommand {
  @override
  String get method => 'skip_migration';

  @override
  Map<String, dynamic>? get params => null;
}
