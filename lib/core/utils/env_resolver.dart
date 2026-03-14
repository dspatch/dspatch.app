// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../models/workspace_config.dart';

/// Pure utility for workspace environment variable resolution.
class EnvResolver {
  EnvResolver._();

  static const _systemEnvPrefix = 'DSPATCH_';

  /// Computes the effective env map for a single agent.
  static Map<String, String> resolveAgentEnv({
    required Map<String, String> globalEnv,
    required Map<String, String> agentEnv,
    required List<String> requiredEnv,
  }) {
    final merged = <String, String>{};

    if (requiredEnv.isEmpty) {
      merged.addAll(globalEnv);
      merged.addAll(agentEnv);
    } else {
      for (final key in requiredEnv) {
        if (agentEnv.containsKey(key)) {
          merged[key] = agentEnv[key]!;
        } else if (globalEnv.containsKey(key)) {
          merged[key] = globalEnv[key]!;
        }
      }
    }

    merged.removeWhere(
        (key, _) => key.toUpperCase().startsWith(_systemEnvPrefix));
    return merged;
  }

  /// Collects the union of all `requiredEnv` keys across templates.
  static Set<String> collectAllRequiredKeys(
    Map<String, AgentConfig> agents,
    Map<String, List<String>> templateRequiredEnv,
  ) {
    final keys = <String>{};
    _collectKeysRecursive(agents, templateRequiredEnv, keys);
    return keys;
  }

  static void _collectKeysRecursive(
    Map<String, AgentConfig> agents,
    Map<String, List<String>> templateRequiredEnv,
    Set<String> keys,
  ) {
    for (final agent in agents.values) {
      final required = templateRequiredEnv[agent.template];
      if (required != null) keys.addAll(required);
      if (agent.subAgents.isNotEmpty) {
        _collectKeysRecursive(agent.subAgents, templateRequiredEnv, keys);
      }
    }
  }
}
