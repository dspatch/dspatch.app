// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for workspace config parsing and validation.
///
/// Bug fix: `validate_workspace_config` uses `yaml: String` (not `config: Map`).
/// Bug fix: `resolve_workspace_templates` uses `workspace_id: String` (not `config: Map`).
library;

import '../engine_responses.dart';
import 'command.dart';

class ParseWorkspaceConfig
    extends EngineCommand<ParseWorkspaceConfigResponse> {
  ParseWorkspaceConfig({required this.yaml});
  final String yaml;

  @override
  String get method => 'parse_workspace_config';

  @override
  Map<String, dynamic> get params => {'yaml': yaml};

  @override
  ParseWorkspaceConfigResponse parseResponse(Map<String, dynamic> result) =>
      ParseWorkspaceConfigResponse.fromJson(result);
}

/// Bug fix: Rust expects `yaml: String`, not `config: Map`.
class ValidateWorkspaceConfig extends EngineCommand<ValidationResult> {
  ValidateWorkspaceConfig({required this.yaml});
  final String yaml;

  @override
  String get method => 'validate_workspace_config';

  @override
  Map<String, dynamic> get params => {'yaml': yaml};

  @override
  ValidationResult parseResponse(Map<String, dynamic> result) =>
      ValidationResult.fromJson(result);
}

class EncodeWorkspaceYaml extends EngineCommand<EncodeWorkspaceYamlResponse> {
  EncodeWorkspaceYaml({required this.config});
  final Map<String, dynamic> config;

  @override
  String get method => 'encode_workspace_yaml';

  @override
  Map<String, dynamic> get params => {'config': config};

  @override
  EncodeWorkspaceYamlResponse parseResponse(Map<String, dynamic> result) =>
      EncodeWorkspaceYamlResponse.fromJson(result);
}

/// Bug fix: Rust expects `workspace_id: String`, not `config: Map`.
class ResolveWorkspaceTemplates
    extends EngineCommand<TemplateResolutionResult> {
  ResolveWorkspaceTemplates({required this.workspaceId});
  final String workspaceId;

  @override
  String get method => 'resolve_workspace_templates';

  @override
  Map<String, dynamic> get params => {'workspace_id': workspaceId};

  @override
  TemplateResolutionResult parseResponse(Map<String, dynamic> result) =>
      TemplateResolutionResult.fromJson(result);
}
