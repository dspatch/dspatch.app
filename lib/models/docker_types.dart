// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed response models for Docker engine commands.
library;

import 'commands/command.dart';

class DockerStatus extends EngineResponse {
  const DockerStatus({
    required this.available,
    this.version,
    this.apiVersion,
    this.os,
    this.arch,
    this.containers,
    this.images,
  });

  final bool available;
  final String? version;
  final String? apiVersion;
  final String? os;
  final String? arch;
  final int? containers;
  final int? images;

  factory DockerStatus.fromJson(Map<String, dynamic> json) {
    return DockerStatus(
      available: json['available'] as bool? ?? false,
      version: json['version'] as String?,
      apiVersion: json['api_version'] as String?,
      os: json['os'] as String?,
      arch: json['arch'] as String?,
      containers: json['containers'] as int?,
      images: json['images'] as int?,
    );
  }
}

class ListContainersResponse extends EngineResponse {
  const ListContainersResponse({required this.containers});

  final List<ContainerSummary> containers;

  factory ListContainersResponse.fromJson(Map<String, dynamic> json) {
    return ListContainersResponse(
      containers: (json['containers'] as List<dynamic>?)
              ?.map((e) => ContainerSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ContainerSummary {
  const ContainerSummary({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.status,
    this.port,
    required this.created,
  });

  final String id;
  final String name;
  final String image;
  final String state;
  final String status;
  final int? port;
  final String created;

  factory ContainerSummary.fromJson(Map<String, dynamic> json) {
    return ContainerSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      state: json['state'] as String? ?? '',
      status: json['status'] as String? ?? '',
      port: json['port'] as int?,
      created: json['created'] as String? ?? '',
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
