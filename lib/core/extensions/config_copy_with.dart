// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';

/// `copyWith` extensions for FRB-generated config types that lack them.
///
/// FRB generates plain classes without Freezed-style copyWith, so we add
/// them here for the workspace config editor widgets.

// Sentinel to distinguish "not provided" from explicit null.
const _sentinel = Object();

extension WorkspaceConfigCopyWith on WorkspaceConfig {
  WorkspaceConfig copyWith({
    String? name,
    Map<String, String>? env,
    Map<String, AgentConfig>? agents,
    List<String>? agentOrder,
    Object? workspaceDir = _sentinel,
    List<MountConfig>? mounts,
    DockerConfig? docker,
  }) {
    return WorkspaceConfig(
      name: name ?? this.name,
      env: env ?? this.env,
      agents: agents ?? this.agents,
      agentOrder: agentOrder ?? this.agentOrder,
      workspaceDir: workspaceDir == _sentinel
          ? this.workspaceDir
          : workspaceDir as String?,
      mounts: mounts ?? this.mounts,
      docker: docker ?? this.docker,
    );
  }
}

extension AgentConfigCopyWith on AgentConfig {
  AgentConfig copyWith({
    String? template,
    Map<String, String>? env,
    Map<String, AgentConfig>? subAgents,
    List<String>? subAgentOrder,
    List<String>? peers,
    Object? autoStart = _sentinel,
  }) {
    return AgentConfig(
      template: template ?? this.template,
      env: env ?? this.env,
      subAgents: subAgents ?? this.subAgents,
      subAgentOrder: subAgentOrder ?? this.subAgentOrder,
      peers: peers ?? this.peers,
      autoStart:
          autoStart == _sentinel ? this.autoStart : autoStart as bool?,
    );
  }
}

extension DockerConfigCopyWith on DockerConfig {
  DockerConfig copyWith({
    Object? memoryLimit = _sentinel,
    Object? cpuLimit = _sentinel,
    String? networkMode,
    List<String>? ports,
    bool? gpu,
    bool? homePersistence,
    Object? homeSize = _sentinel,
  }) {
    return DockerConfig(
      memoryLimit: memoryLimit == _sentinel
          ? this.memoryLimit
          : memoryLimit as String?,
      cpuLimit:
          cpuLimit == _sentinel ? this.cpuLimit : cpuLimit as double?,
      networkMode: networkMode ?? this.networkMode,
      ports: ports ?? this.ports,
      gpu: gpu ?? this.gpu,
      homePersistence: homePersistence ?? this.homePersistence,
      homeSize:
          homeSize == _sentinel ? this.homeSize : homeSize as String?,
    );
  }
}

extension MountConfigCopyWith on MountConfig {
  MountConfig copyWith({
    String? hostPath,
    String? containerPath,
    bool? readOnly,
  }) {
    return MountConfig(
      hostPath: hostPath ?? this.hostPath,
      containerPath: containerPath ?? this.containerPath,
      readOnly: readOnly ?? this.readOnly,
    );
  }
}
