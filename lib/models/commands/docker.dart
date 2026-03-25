// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for Docker operations.
library;

import '../docker_types.dart';
import 'command.dart';

class DetectDockerStatus extends EngineCommand<DockerStatus> {
  @override
  String get method => 'detect_docker_status';

  @override
  Map<String, dynamic>? get params => null;

  @override
  DockerStatus parseResponse(Map<String, dynamic> result) =>
      DockerStatus.fromJson(result);
}

class ListContainers extends EngineCommand<ListContainersResponse> {
  @override
  String get method => 'list_containers';

  @override
  Map<String, dynamic>? get params => null;

  @override
  ListContainersResponse parseResponse(Map<String, dynamic> result) =>
      ListContainersResponse.fromJson(result);
}

/// Bug fix: Rust expects `run_id`, not `container_id`.
class GetContainerStats extends EngineCommand<ContainerStats> {
  GetContainerStats({required this.runId});
  final String runId;

  @override
  String get method => 'container_stats';

  @override
  Map<String, dynamic> get params => {'run_id': runId};

  @override
  ContainerStats parseResponse(Map<String, dynamic> result) =>
      ContainerStats.fromJson(result);
}

/// Starts a runtime image build. Returns immediately — build output is
/// streamed as ephemeral events (`build_log_line`, `build_complete`).
class BuildRuntimeImage extends VoidEngineCommand {
  @override
  String get method => 'build_runtime_image';

  @override
  Map<String, dynamic>? get params => null;
}

class DeleteRuntimeImage extends VoidEngineCommand {
  @override
  String get method => 'delete_runtime_image';

  @override
  Map<String, dynamic>? get params => null;
}

class StopContainer extends VoidEngineCommand {
  StopContainer({required this.id});
  final String id;

  @override
  String get method => 'stop_container';

  @override
  Map<String, dynamic> get params => {'id': id};
}

class RemoveContainer extends VoidEngineCommand {
  RemoveContainer({required this.id});
  final String id;

  @override
  String get method => 'remove_container';

  @override
  Map<String, dynamic> get params => {'id': id};
}

class StopAllContainers extends EngineCommand<CountResponse> {
  @override
  String get method => 'stop_all_containers';

  @override
  Map<String, dynamic>? get params => null;

  @override
  CountResponse parseResponse(Map<String, dynamic> result) =>
      CountResponse.fromJson(result);
}

class DeleteStoppedContainers extends EngineCommand<CountResponse> {
  @override
  String get method => 'delete_stopped_containers';

  @override
  Map<String, dynamic>? get params => null;

  @override
  CountResponse parseResponse(Map<String, dynamic> result) =>
      CountResponse.fromJson(result);
}

class CleanOrphanedContainers extends EngineCommand<CountResponse> {
  @override
  String get method => 'clean_orphaned_containers';

  @override
  Map<String, dynamic>? get params => null;

  @override
  CountResponse parseResponse(Map<String, dynamic> result) =>
      CountResponse.fromJson(result);
}

/// Response for the fetch_router_versions command.
class RouterVersionsResponse extends EngineResponse {
  const RouterVersionsResponse({required this.versions});
  final List<String> versions;

  factory RouterVersionsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['versions'] as List?)?.cast<String>() ?? [];
    return RouterVersionsResponse(versions: list);
  }
}

class FetchRouterVersions extends EngineCommand<RouterVersionsResponse> {
  @override
  String get method => 'fetch_router_versions';

  @override
  Map<String, dynamic>? get params => null;

  @override
  RouterVersionsResponse parseResponse(Map<String, dynamic> result) =>
      RouterVersionsResponse.fromJson(result);
}
