// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for workspace CRUD and lifecycle.
///
/// Bug fix: `delete_workspace_run` uses `run_id` (not `id`).
library;

import 'command.dart';

class CreateWorkspace extends VoidEngineCommand {
  CreateWorkspace({required this.projectPath, required this.configYaml});
  final String projectPath;
  final String configYaml;

  @override
  String get method => 'create_workspace';

  @override
  Map<String, dynamic> get params => {
        'project_path': projectPath,
        'config_yaml': configYaml,
      };
}

class DeleteWorkspace extends VoidEngineCommand {
  DeleteWorkspace({required this.id});
  final String id;

  @override
  String get method => 'delete_workspace';

  @override
  Map<String, dynamic> get params => {'id': id};
}

/// Transitional: per the communication report, workspace reads should go
/// through Drift. This command exists for compatibility and may be removed.
class GetWorkspace extends VoidEngineCommand {
  GetWorkspace({required this.id});
  final String id;

  @override
  String get method => 'get_workspace';

  @override
  Map<String, dynamic> get params => {'id': id};
}

class LaunchWorkspace extends VoidEngineCommand {
  LaunchWorkspace({required this.id});
  final String id;

  @override
  String get method => 'launch_workspace';

  @override
  Map<String, dynamic> get params => {'id': id};
}

class StopWorkspace extends VoidEngineCommand {
  StopWorkspace({required this.id});
  final String id;

  @override
  String get method => 'stop_workspace';

  @override
  Map<String, dynamic> get params => {'id': id};
}

/// Bug fix: Rust expects `run_id`, not `id`.
class DeleteWorkspaceRun extends VoidEngineCommand {
  DeleteWorkspaceRun({required this.runId});
  final String runId;

  @override
  String get method => 'delete_workspace_run';

  @override
  Map<String, dynamic> get params => {'run_id': runId};
}

class DeleteNonActiveRuns extends VoidEngineCommand {
  DeleteNonActiveRuns({required this.workspaceId});
  final String workspaceId;

  @override
  String get method => 'delete_non_active_runs';

  @override
  Map<String, dynamic> get params => {'workspace_id': workspaceId};
}

class ListDirectory extends VoidEngineCommand {
  ListDirectory({required this.path});
  final String path;

  @override
  String get method => 'list_directory';

  @override
  Map<String, dynamic> get params => {'path': path};
}
