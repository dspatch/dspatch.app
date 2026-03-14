// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../models/workspace_config.dart';

/// Pure utility for agent map operations (add, remove, rename).
///
/// Centralizes the logic duplicated between the top-level agent editor
/// and recursive sub-agent editors. All methods are static and operate
/// on a `Map<String, AgentConfig>`, returning a new map.
class AgentMapHelpers {
  AgentMapHelpers._();

  /// Adds a new empty agent with a unique key.
  static Map<String, AgentConfig> addAgent(
    Map<String, AgentConfig> agents, {
    String prefix = 'agent',
  }) {
    final result = Map<String, AgentConfig>.of(agents);
    var key = '$prefix-${result.length + 1}';
    while (result.containsKey(key)) {
      key = '$key-new';
    }
    result[key] = const AgentConfig(
      template: '',
      env: {},
      subAgents: {},
      subAgentOrder: [],
      peers: [],
    );
    return result;
  }

  /// Removes an agent and cleans up peer references in siblings.
  static Map<String, AgentConfig> removeAgent(
    Map<String, AgentConfig> agents,
    String key,
  ) {
    final result = Map<String, AgentConfig>.of(agents);
    result.remove(key);
    return result.map((k, v) {
      final peers = v.peers.where((p) => p != key).toList();
      return MapEntry(k, v.copyWith(peers: peers));
    });
  }

  /// Renames an agent key and updates all peer references.
  static Map<String, AgentConfig> renameAgent(
    Map<String, AgentConfig> agents,
    String oldKey,
    String newKey,
  ) {
    if (oldKey == newKey || newKey.isEmpty) return agents;
    final result = Map<String, AgentConfig>.of(agents);
    final config = result.remove(oldKey);
    if (config == null) return agents;
    result[newKey] = config;
    return result.map((k, v) {
      final peers = v.peers.map((p) => p == oldKey ? newKey : p).toList();
      return MapEntry(k, v.copyWith(peers: peers));
    });
  }
}
