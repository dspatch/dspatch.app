// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Workspace configuration types for the visual editor and YAML parsing.
///
/// These replace the FRB-generated types from the old dspatch_sdk package.
library;


class WorkspaceConfig {
  const WorkspaceConfig({
    required this.name,
    required this.env,
    required this.agents,
    required this.agentOrder,
    this.workspaceDir,
    required this.mounts,
    required this.docker,
  });

  final String name;
  final Map<String, String> env;
  final Map<String, AgentConfig> agents;
  final List<String> agentOrder;
  final String? workspaceDir;
  final List<MountConfig> mounts;
  final DockerConfig docker;

  factory WorkspaceConfig.fromJson(Map<String, dynamic> json) {
    return WorkspaceConfig(
      name: json['name'] as String? ?? '',
      env: (json['env'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      agents: (json['agents'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, AgentConfig.fromJson(v as Map<String, dynamic>))) ??
          {},
      agentOrder: (json['agent_order'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      workspaceDir: json['workspace_dir'] as String?,
      mounts: (json['mounts'] as List<dynamic>?)
              ?.map((e) => MountConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      docker: json['docker'] != null
          ? DockerConfig.fromJson(json['docker'] as Map<String, dynamic>)
          : const DockerConfig(
              networkMode: 'host',
              ports: [],
              gpu: false,
              homePersistence: false,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'env': env,
        'agents': agents.map((k, v) => MapEntry(k, v.toJson())),
        'agent_order': agentOrder,
        if (workspaceDir != null) 'workspace_dir': workspaceDir,
        'mounts': mounts.map((m) => m.toJson()).toList(),
        'docker': docker.toJson(),
      };
}

class AgentConfig {
  const AgentConfig({
    required this.template,
    required this.env,
    required this.subAgents,
    required this.subAgentOrder,
    required this.peers,
    this.autoStart,
  });

  final String template;
  final Map<String, String> env;
  final Map<String, AgentConfig> subAgents;
  final List<String> subAgentOrder;
  final List<String> peers;
  final bool? autoStart;

  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    return AgentConfig(
      template: json['template'] as String? ?? '',
      env: (json['env'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      subAgents: (json['sub_agents'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, AgentConfig.fromJson(v as Map<String, dynamic>))) ??
          {},
      subAgentOrder: (json['sub_agent_order'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      peers: (json['peers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      autoStart: json['auto_start'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'template': template,
        'env': env,
        'sub_agents': subAgents.map((k, v) => MapEntry(k, v.toJson())),
        'sub_agent_order': subAgentOrder,
        'peers': peers,
        if (autoStart != null) 'auto_start': autoStart,
      };
}

class DockerConfig {
  const DockerConfig({
    this.memoryLimit,
    this.cpuLimit,
    required this.networkMode,
    required this.ports,
    required this.gpu,
    required this.homePersistence,
    this.homeSize,
  });

  final String? memoryLimit;
  final double? cpuLimit;
  final String networkMode;
  final List<String> ports;
  final bool gpu;
  final bool homePersistence;
  final String? homeSize;

  factory DockerConfig.fromJson(Map<String, dynamic> json) {
    return DockerConfig(
      memoryLimit: json['memory_limit'] as String?,
      cpuLimit: (json['cpu_limit'] as num?)?.toDouble(),
      networkMode: json['network_mode'] as String? ?? 'host',
      ports: (json['ports'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      gpu: json['gpu'] as bool? ?? false,
      homePersistence: json['home_persistence'] as bool? ?? false,
      homeSize: json['home_size'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (memoryLimit != null) 'memory_limit': memoryLimit,
        if (cpuLimit != null) 'cpu_limit': cpuLimit,
        'network_mode': networkMode,
        'ports': ports,
        'gpu': gpu,
        'home_persistence': homePersistence,
        if (homeSize != null) 'home_size': homeSize,
      };
}

class MountConfig {
  const MountConfig({
    required this.hostPath,
    required this.containerPath,
    required this.readOnly,
  });

  final String hostPath;
  final String containerPath;
  final bool readOnly;

  factory MountConfig.fromJson(Map<String, dynamic> json) {
    return MountConfig(
      hostPath: json['host_path'] as String? ?? '',
      containerPath: json['container_path'] as String? ?? '',
      readOnly: json['read_only'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'host_path': hostPath,
        'container_path': containerPath,
        'read_only': readOnly,
      };
}
