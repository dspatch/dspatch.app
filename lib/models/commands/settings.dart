// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for API keys, preferences, agent providers, and templates.
library;

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
class GetPreference extends VoidEngineCommand {
  GetPreference({required this.key});
  final String key;

  @override
  String get method => 'get_preference';

  @override
  Map<String, dynamic> get params => {'key': key};
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

class CreateAgentProvider extends VoidEngineCommand {
  CreateAgentProvider({required this.request});
  final Map<String, dynamic> request;

  @override
  String get method => 'create_agent_provider';

  @override
  Map<String, dynamic> get params => request;
}

class UpdateAgentProvider extends VoidEngineCommand {
  UpdateAgentProvider({required this.id, required this.request});
  final String id;
  final Map<String, dynamic> request;

  @override
  String get method => 'update_agent_provider';

  @override
  Map<String, dynamic> get params => {'id': id, ...request};
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

class CreateAgentTemplate extends VoidEngineCommand {
  CreateAgentTemplate({required this.request});
  final Map<String, dynamic> request;

  @override
  String get method => 'create_agent_template';

  @override
  Map<String, dynamic> get params => request;
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
