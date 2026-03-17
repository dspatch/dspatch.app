// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for API keys, preferences, agent providers, and templates.
library;

import '../engine_responses.dart';
import 'command.dart';

// ── API Keys ───────────────────────────────────────────────────────────────

class CreateApiKey extends VoidEngineCommand {
  CreateApiKey({required this.name, required this.value, this.providerName});
  final String name;
  final String value;
  final String? providerName;

  @override
  String get method => 'create_api_key';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'value': value,
        if (providerName != null) 'provider_name': providerName,
      };
}

class DeleteApiKey extends VoidEngineCommand {
  DeleteApiKey({required this.id});
  final String id;

  @override
  String get method => 'delete_api_key';

  @override
  Map<String, dynamic> get params => {'id': id};
}

/// Transitional: per the communication report, key reads should go
/// through Drift. This command exists for compatibility and may be removed.
class GetApiKeyByName extends VoidEngineCommand {
  GetApiKeyByName({required this.name});
  final String name;

  @override
  String get method => 'get_api_key_by_name';

  @override
  Map<String, dynamic> get params => {'name': name};
}

// ── Preferences ────────────────────────────────────────────────────────────

/// Transitional: per the communication report, preference reads should go
/// through Drift. This command exists for compatibility and may be removed.
class GetPreference extends EngineCommand<PreferenceResponse> {
  GetPreference({required this.key});
  final String key;

  @override
  String get method => 'get_preference';

  @override
  Map<String, dynamic> get params => {'key': key};

  @override
  PreferenceResponse parseResponse(Map<String, dynamic> result) =>
      PreferenceResponse.fromJson(result);
}

class SetPreference extends VoidEngineCommand {
  SetPreference({required this.key, required this.value});
  final String key;
  final String value;

  @override
  String get method => 'set_preference';

  @override
  Map<String, dynamic> get params => {'key': key, 'value': value};
}

class DeletePreference extends VoidEngineCommand {
  DeletePreference({required this.key});
  final String key;

  @override
  String get method => 'delete_preference';

  @override
  Map<String, dynamic> get params => {'key': key};
}

// ── Agent Providers ────────────────────────────────────────────────────────

/// Create a new agent provider. Wire format uses snake_case to match
/// the Rust `CreateAgentProviderRequest` struct.
class CreateAgentProvider extends VoidEngineCommand {
  CreateAgentProvider({
    required this.name,
    required this.sourceType,
    required this.entryPoint,
    this.sourcePath,
    this.gitUrl,
    this.gitBranch,
    this.description,
    this.readme,
    this.requiredEnv = const [],
    this.requiredMounts = const [],
    this.fields = const {},
    this.hubSlug,
    this.hubAuthor,
    this.hubCategory,
    this.hubTags = const [],
    this.hubVersion,
    this.hubRepoUrl,
    this.hubCommitHash,
  });

  final String name;
  final String sourceType;
  final String entryPoint;
  final String? sourcePath;
  final String? gitUrl;
  final String? gitBranch;
  final String? description;
  final String? readme;
  final List<String> requiredEnv;
  final List<String> requiredMounts;
  final Map<String, String> fields;
  final String? hubSlug;
  final String? hubAuthor;
  final String? hubCategory;
  final List<String> hubTags;
  final int? hubVersion;
  final String? hubRepoUrl;
  final String? hubCommitHash;

  @override
  String get method => 'create_agent_provider';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'source_type': sourceType,
        'entry_point': entryPoint,
        if (sourcePath != null) 'source_path': sourcePath,
        if (gitUrl != null) 'git_url': gitUrl,
        if (gitBranch != null) 'git_branch': gitBranch,
        if (description != null) 'description': description,
        if (readme != null) 'readme': readme,
        'required_env': requiredEnv,
        'required_mounts': requiredMounts,
        'fields': fields,
        if (hubSlug != null) 'hub_slug': hubSlug,
        if (hubAuthor != null) 'hub_author': hubAuthor,
        if (hubCategory != null) 'hub_category': hubCategory,
        if (hubTags.isNotEmpty) 'hub_tags': hubTags,
        if (hubVersion != null) 'hub_version': hubVersion,
        if (hubRepoUrl != null) 'hub_repo_url': hubRepoUrl,
        if (hubCommitHash != null) 'hub_commit_hash': hubCommitHash,
      };
}

/// Update an existing agent provider. Wire format uses snake_case to match
/// the Rust `UpdateAgentProviderRequest` struct.
class UpdateAgentProvider extends VoidEngineCommand {
  UpdateAgentProvider({
    required this.id,
    this.name,
    this.sourceType,
    this.entryPoint,
    this.sourcePath,
    this.gitUrl,
    this.gitBranch,
    this.description,
    this.readme,
    this.requiredEnv,
    this.requiredMounts,
    this.fields,
    this.hubSlug,
    this.hubAuthor,
    this.hubCategory,
    this.hubTags,
    this.hubVersion,
    this.hubRepoUrl,
    this.hubCommitHash,
  });

  final String id;
  final String? name;
  final String? sourceType;
  final String? entryPoint;
  final String? sourcePath;
  final String? gitUrl;
  final String? gitBranch;
  final String? description;
  final String? readme;
  final List<String>? requiredEnv;
  final List<String>? requiredMounts;
  final Map<String, String>? fields;
  final String? hubSlug;
  final String? hubAuthor;
  final String? hubCategory;
  final List<String>? hubTags;
  final int? hubVersion;
  final String? hubRepoUrl;
  final String? hubCommitHash;

  @override
  String get method => 'update_agent_provider';

  @override
  Map<String, dynamic> get params => {
        'id': id,
        if (name != null) 'name': name,
        if (sourceType != null) 'source_type': sourceType,
        if (entryPoint != null) 'entry_point': entryPoint,
        if (sourcePath != null) 'source_path': sourcePath,
        if (gitUrl != null) 'git_url': gitUrl,
        if (gitBranch != null) 'git_branch': gitBranch,
        if (description != null) 'description': description,
        if (readme != null) 'readme': readme,
        if (requiredEnv != null) 'required_env': requiredEnv,
        if (requiredMounts != null) 'required_mounts': requiredMounts,
        if (fields != null) 'fields': fields,
        if (hubSlug != null) 'hub_slug': hubSlug,
        if (hubAuthor != null) 'hub_author': hubAuthor,
        if (hubCategory != null) 'hub_category': hubCategory,
        if (hubTags != null) 'hub_tags': hubTags,
        if (hubVersion != null) 'hub_version': hubVersion,
        if (hubRepoUrl != null) 'hub_repo_url': hubRepoUrl,
        if (hubCommitHash != null) 'hub_commit_hash': hubCommitHash,
      };
}

class DeleteAgentProvider extends VoidEngineCommand {
  DeleteAgentProvider({required this.id});
  final String id;

  @override
  String get method => 'delete_agent_provider';

  @override
  Map<String, dynamic> get params => {'id': id};
}

/// Transitional: per the communication report, provider reads should go
/// through Drift. This command exists for compatibility and may be removed.
class GetAgentProvider extends VoidEngineCommand {
  GetAgentProvider({required this.id});
  final String id;

  @override
  String get method => 'get_agent_provider';

  @override
  Map<String, dynamic> get params => {'id': id};
}

// ── Agent Templates ────────────────────────────────────────────────────────

class CreateAgentTemplate extends EngineCommand<CreateTemplateResponse> {
  CreateAgentTemplate({required this.name, required this.sourceUri});
  final String name;
  final String sourceUri;

  @override
  String get method => 'create_agent_template';

  @override
  Map<String, dynamic> get params => {
        'name': name,
        'source_uri': sourceUri,
      };

  @override
  CreateTemplateResponse parseResponse(Map<String, dynamic> result) =>
      CreateTemplateResponse.fromJson(result);
}

class UpdateAgentTemplate extends VoidEngineCommand {
  UpdateAgentTemplate({
    required this.id,
    required this.name,
    required this.sourceUri,
  });
  final String id;
  final String name;
  final String sourceUri;

  @override
  String get method => 'update_agent_template';

  @override
  Map<String, dynamic> get params => {
        'id': id,
        'name': name,
        'source_uri': sourceUri,
      };
}

class DeleteAgentTemplate extends VoidEngineCommand {
  DeleteAgentTemplate({required this.id});
  final String id;

  @override
  String get method => 'delete_agent_template';

  @override
  Map<String, dynamic> get params => {'id': id};
}
