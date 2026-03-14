// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed response models for Docker engine commands.
library;

import 'commands/command.dart';

class DockerStatus extends EngineResponse {
  const DockerStatus({
    required this.isInstalled,
    required this.isRunning,
    required this.hasSysbox,
    required this.hasNvidiaRuntime,
    required this.hasRuntimeImage,
    this.runtimeImageSize,
    this.dockerVersion,
  });

  final bool isInstalled;
  final bool isRunning;
  final bool hasSysbox;
  final bool hasNvidiaRuntime;
  final bool hasRuntimeImage;
  final String? runtimeImageSize;
  final String? dockerVersion;

  factory DockerStatus.fromJson(Map<String, dynamic> json) {
    return DockerStatus(
      isInstalled: json['isInstalled'] as bool? ?? false,
      isRunning: json['isRunning'] as bool? ?? false,
      hasSysbox: json['hasSysbox'] as bool? ?? false,
      hasNvidiaRuntime: json['hasNvidiaRuntime'] as bool? ?? false,
      hasRuntimeImage: json['hasRuntimeImage'] as bool? ?? false,
      runtimeImageSize: json['runtimeImageSize'] as String?,
      dockerVersion: json['dockerVersion'] as String?,
    );
  }
}

class ListContainersResponse extends EngineResponse {
  const ListContainersResponse({required this.containers});

  final List<ContainerSummary> containers;

  factory ListContainersResponse.fromJson(Map<String, dynamic> json) {
    // The engine returns Vec<ContainerSummary> directly. The Dart protocol
    // layer wraps non-Map data as {'value': ...}, so check both keys.
    final list = json['containers'] as List<dynamic>?
        ?? json['value'] as List<dynamic>?
        ?? [];
    return ListContainersResponse(
      containers: list
          .map((e) => ContainerSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Matches Rust `ContainerSummary` in `domain/services/docker.rs`.
class ContainerSummary {
  const ContainerSummary({
    required this.id,
    required this.names,
    required this.image,
    required this.state,
    required this.status,
    required this.created,
  });

  final String id;
  final List<String> names;
  final String image;
  final String state;
  final String status;
  /// Unix timestamp in seconds.
  final int created;

  /// Display name: first entry from `names`, stripped of leading '/'.
  String get name => names.isNotEmpty
      ? names.first.replaceFirst(RegExp(r'^/'), '')
      : id;

  factory ContainerSummary.fromJson(Map<String, dynamic> json) {
    return ContainerSummary(
      id: json['id'] as String? ?? '',
      names: (json['names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      image: json['image'] as String? ?? '',
      state: json['state'] as String? ?? '',
      status: json['status'] as String? ?? '',
      created: json['created'] as int? ?? 0,
    );
  }
}

class ContainerStats extends EngineResponse {
  const ContainerStats({
    required this.cpuPercent,
    required this.memoryUsage,
    required this.memoryLimit,
    required this.networkRx,
    required this.networkTx,
  });

  final double cpuPercent;
  final int memoryUsage;
  final int memoryLimit;
  final int networkRx;
  final int networkTx;

  factory ContainerStats.fromJson(Map<String, dynamic> json) {
    return ContainerStats(
      cpuPercent: (json['cpu_percent'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: json['memory_usage'] as int? ?? 0,
      memoryLimit: json['memory_limit'] as int? ?? 0,
      networkRx: json['network_rx'] as int? ?? 0,
      networkTx: json['network_tx'] as int? ?? 0,
    );
  }
}
