// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import '../../../database/engine_database.dart';

/// Whether the item is a provider or a template.
enum AgentItemKind { provider, template }

/// Unified display model for the merged providers + templates list.
class AgentListItem {
  final AgentItemKind kind;
  final String id;
  final String name;
  final String? description;
  final String updatedAt;

  // Provider-only fields (null for templates)
  final AgentProvider? provider;

  // Template-only fields (null for providers)
  final AgentTemplate? template;

  AgentListItem.fromProvider(AgentProvider p)
      : kind = AgentItemKind.provider,
        id = p.id,
        name = p.name,
        description = p.description,
        updatedAt = p.updatedAt,
        provider = p,
        template = null;

  AgentListItem.fromTemplate(AgentTemplate t)
      : kind = AgentItemKind.template,
        id = t.id,
        name = t.name,
        description = null,
        updatedAt = t.updatedAt,
        provider = null,
        template = t;

  bool get isTemplate => kind == AgentItemKind.template;
}
