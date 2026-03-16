// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'engine_connection.dart';
import 'protocol/protocol.dart';
import '../models/commands/command.dart';

/// Exception thrown when the engine returns an error response to a command.
class EngineException implements Exception {
  final String code;
  final String message;

  const EngineException({required this.code, required this.message});

  @override
  String toString() => 'EngineException($code): $message';
}

/// Exception thrown when the engine connection fails.
class EngineConnectionException implements Exception {
  final String message;
  const EngineConnectionException(this.message);

  @override
  String toString() => 'EngineConnectionException: $message';
}

/// High-level typed client for the dspatch engine.
///
/// Wraps [EngineConnection] with typed command methods that return futures.
/// Each method constructs a [ClientFrame], sends it over the WebSocket,
/// and returns the result (or throws [EngineException] on error).
///
/// This class is pure Dart — no Flutter imports. Shared by GUI and future CLI.
class EngineClient {
  final EngineConnection connection;
  final _uuid = const Uuid();

  EngineClient(this.connection);

  // ── Public Streams (delegated from connection) ────────────────────────

  /// Stream of table invalidation events.
  Stream<List<String>> get invalidations => connection.invalidations;

  /// Stream of ephemeral events.
  Stream<EventFrame> get events => connection.events;

  /// Stream of connection state changes.
  Stream<bool> get connectionState => connection.connectionState;

  /// Whether the connection is currently active.
  bool get isConnected => connection.isConnected;

  // ── Command Infrastructure ────────────────────────────────────────────

  /// Sends a command to the engine and returns the result data.
  ///
  /// Throws [EngineException] if the engine returns an error response.
  /// Throws [StateError] if not connected.
  ///
  /// Private — external callers must use [send] with typed commands.
  Future<Map<String, dynamic>> _sendCommand(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    final id = _uuid.v4();
    final frame = ClientFrame.command(id: id, method: method, params: params);

    // Register the pending future BEFORE sending, to avoid race conditions.
    final responseFuture = connection.registerPendingCommand(id);

    // Send the frame.
    connection.sendRaw(jsonEncode(frame.toJson()));

    // Wait for the response.
    final response = await responseFuture;

    return switch (response) {
      ResultFrame(:final data) => data,
      ErrorFrame(:final code, :final message) =>
        throw EngineException(code: code, message: message),
      _ => throw StateError('Unexpected response type: $response'),
    };
  }

  /// Sends a typed command and returns a typed response.
  ///
  /// All external callers must use this method with typed [EngineCommand]
  /// subclasses instead of calling `_sendCommand` directly.
  Future<R> send<R extends EngineResponse>(EngineCommand<R> command) async {
    final result = await _sendCommand(command.method, command.params ?? const {});
    return command.parseResponse(result);
  }

  // ── Workspace Commands ────────────────────────────────────────────────

  /// Creates a new workspace from a config YAML string.
  Future<Map<String, dynamic>> createWorkspace({
    required String projectPath,
    required String configYaml,
  }) {
    return _sendCommand('create_workspace', {
      'project_path': projectPath,
      'config_yaml': configYaml,
    });
  }

  /// Launches a workspace container.
  Future<Map<String, dynamic>> launchWorkspace(String workspaceId) {
    return _sendCommand('launch_workspace', {'id': workspaceId});
  }

  /// Stops a running workspace container.
  Future<Map<String, dynamic>> stopWorkspace(String workspaceId) {
    return _sendCommand('stop_workspace', {'id': workspaceId});
  }

  /// Deletes a workspace by ID.
  Future<Map<String, dynamic>> deleteWorkspace(String workspaceId) {
    return _sendCommand('delete_workspace', {'id': workspaceId});
  }

  // ── Agent Interaction Commands ────────────────────────────────────────

  /// Sends user input to a running agent instance.
  Future<Map<String, dynamic>> sendUserInputToAgent({
    required String runId,
    required String instanceId,
    required String text,
  }) {
    return _sendCommand('send_user_input_to_agent', {
      'run_id': runId,
      'instance_id': instanceId,
      'text': text,
    });
  }

  /// Responds to an inquiry.
  Future<Map<String, dynamic>> respondToInquiry({
    required String inquiryId,
    required String response,
    int? choiceIndex,
  }) {
    return _sendCommand('respond_to_inquiry', {
      'inquiry_id': inquiryId,
      'response': response,
      'choice_index': ?choiceIndex,
    });
  }

  // ── API Key Commands ──────────────────────────────────────────────────

  /// Creates a new API key.
  Future<Map<String, dynamic>> createApiKey({
    required String name,
    required String value,
    String? providerName,
  }) {
    return _sendCommand('create_api_key', {
      'name': name,
      'value': value,
      'provider_name': ?providerName,
    });
  }

  /// Deletes an API key by ID.
  Future<Map<String, dynamic>> deleteApiKey(String id) {
    return _sendCommand('delete_api_key', {'id': id});
  }

  // ── Preference Commands ───────────────────────────────────────────────

  /// Gets a preference value by key.
  Future<Map<String, dynamic>> getPreference(String key) {
    return _sendCommand('get_preference', {'key': key});
  }

  /// Sets a preference value.
  Future<Map<String, dynamic>> setPreference(String key, String value) {
    return _sendCommand('set_preference', {'key': key, 'value': value});
  }

  // ── Agent Provider Commands ───────────────────────────────────────

  Future<Map<String, dynamic>> createAgentProvider({
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('create_agent_provider', request);
  }

  Future<Map<String, dynamic>> updateAgentProvider({
    required String id,
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('update_agent_provider', {
      'id': id,
      ...request,
    });
  }

  Future<Map<String, dynamic>> deleteAgentProvider(String id) {
    return _sendCommand('delete_agent_provider', {'id': id});
  }

  // ── Agent Template Commands ───────────────────────────────────────

  Future<Map<String, dynamic>> createAgentTemplate({
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('create_agent_template', request);
  }

  Future<Map<String, dynamic>> updateAgentTemplate({
    required String id,
    required String name,
    required String sourceUri,
  }) {
    return _sendCommand('update_agent_template', {
      'id': id,
      'name': name,
      'source_uri': sourceUri,
    });
  }

  Future<Map<String, dynamic>> deleteAgentTemplate(String id) {
    return _sendCommand('delete_agent_template', {'id': id});
  }

  // ── Workspace Instance Commands ───────────────────────────────────

  Future<Map<String, dynamic>> startRootInstance({
    required String runId,
    required String agentKey,
  }) {
    return _sendCommand('start_root_instance', {
      'run_id': runId,
      'agent_key': agentKey,
    });
  }

  Future<Map<String, dynamic>> startSubInstance({
    required String runId,
    required String parentInstanceId,
    required String agentKey,
  }) {
    return _sendCommand('start_sub_instance', {
      'run_id': runId,
      'parent_instance_id': parentInstanceId,
      'agent_key': agentKey,
    });
  }

  Future<Map<String, dynamic>> stopInstance({
    required String runId,
    required String instanceId,
  }) {
    return _sendCommand('stop_instance', {
      'run_id': runId,
      'instance_id': instanceId,
    });
  }

  Future<Map<String, dynamic>> interruptInstance({
    required String runId,
    required String instanceId,
  }) {
    return _sendCommand('interrupt_instance', {
      'run_id': runId,
      'instance_id': instanceId,
    });
  }

  Future<Map<String, dynamic>> cleanupStaleInstances({
    required String runId,
  }) {
    return _sendCommand('cleanup_stale_instances', {'run_id': runId});
  }

  // ── Workspace Run Commands ────────────────────────────────────────

  Future<Map<String, dynamic>> deleteWorkspaceRun(String id) {
    return _sendCommand('delete_workspace_run', {'id': id});
  }

  Future<Map<String, dynamic>> deleteNonActiveRuns({
    required String workspaceId,
  }) {
    return _sendCommand('delete_non_active_runs', {
      'workspace_id': workspaceId,
    });
  }

  // ── Docker / Engine Commands ──────────────────────────────────────

  Future<Map<String, dynamic>> detectDockerStatus() {
    return _sendCommand('detect_docker_status');
  }

  Stream<String> buildRuntimeImage() async* {
    final result = await _sendCommand('build_runtime_image');
    final lines = (result['lines'] as List<dynamic>?)?.cast<String>() ?? [];
    for (final line in lines) {
      yield line;
    }
  }

  Future<Map<String, dynamic>> deleteRuntimeImage() {
    return _sendCommand('delete_runtime_image');
  }

  Future<List<Map<String, dynamic>>> listContainers() async {
    final result = await _sendCommand('list_containers');
    return (result['containers'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<Map<String, dynamic>> stopContainer({required String id}) {
    return _sendCommand('stop_container', {'id': id});
  }

  Future<Map<String, dynamic>> removeContainer({required String id}) {
    return _sendCommand('remove_container', {'id': id});
  }

  Future<Map<String, dynamic>> stopAllContainers() {
    return _sendCommand('stop_all_containers');
  }

  Future<Map<String, dynamic>> deleteStoppedContainers() {
    return _sendCommand('delete_stopped_containers');
  }

  Future<Map<String, dynamic>> cleanOrphanedContainers() {
    return _sendCommand('clean_orphaned_containers');
  }

  Future<Map<String, dynamic>> containerStats({required String containerId}) {
    return _sendCommand('container_stats', {'container_id': containerId});
  }

  // ── Config / Utility Commands ─────────────────────────────────────

  Future<Map<String, dynamic>> parseWorkspaceConfig({
    required String yaml,
  }) {
    return _sendCommand('parse_workspace_config', {'yaml': yaml});
  }

  Future<Map<String, dynamic>> encodeWorkspaceYaml({
    required Map<String, dynamic> config,
  }) {
    return _sendCommand('encode_workspace_yaml', {'config': config});
  }

  Future<Map<String, dynamic>> validateWorkspaceConfig({
    required Map<String, dynamic> config,
  }) {
    return _sendCommand('validate_workspace_config', {'config': config});
  }

  Future<Map<String, dynamic>> resolveWorkspaceTemplates({
    required Map<String, dynamic> config,
  }) {
    return _sendCommand('resolve_workspace_templates', {'config': config});
  }

  Future<Map<String, dynamic>> encryptString({
    required String plaintext,
    required String keyId,
  }) {
    return _sendCommand('encrypt_string', {
      'plaintext': plaintext,
      'key_id': keyId,
    });
  }

  Future<Map<String, dynamic>> decryptString({required String value}) {
    return _sendCommand('decrypt_string', {'value': value});
  }

  Future<Map<String, dynamic>> packageInspectorEntries({
    required String runId,
  }) {
    return _sendCommand('package_inspector_entries', {'run_id': runId});
  }

  // ── Hub Commands ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> hubBrowseAgents({
    String? search,
    String? category,
    String? cursor,
    int? perPage,
  }) {
    return _sendCommand('hub_browse_agents', {
      'search': ?search,
      'category': ?category,
      'cursor': ?cursor,
      'per_page': ?perPage,
    });
  }

  Future<Map<String, dynamic>> hubBrowseWorkspaces({
    String? search,
    String? category,
    String? cursor,
    int? perPage,
  }) {
    return _sendCommand('hub_browse_workspaces', {
      'search': ?search,
      'category': ?category,
      'cursor': ?cursor,
      'per_page': ?perPage,
    });
  }

  Future<Map<String, dynamic>> hubAgentCategories() {
    return _sendCommand('hub_agent_categories');
  }

  Future<Map<String, dynamic>> hubWorkspaceCategories() {
    return _sendCommand('hub_workspace_categories');
  }

  Future<Map<String, dynamic>> hubResolveAgent({required String slug}) {
    return _sendCommand('hub_resolve_agent', {'slug': slug});
  }

  Future<Map<String, dynamic>> hubResolveWorkspaceDetails({
    required String slug,
  }) {
    return _sendCommand('hub_resolve_workspace_details', {'slug': slug});
  }

  Future<Map<String, dynamic>> hubSubmitAgent({
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('hub_submit_agent', request);
  }

  Future<Map<String, dynamic>> hubSubmitTemplate({
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('hub_submit_template', request);
  }

  Future<Map<String, dynamic>> hubSubmitWorkspace({
    required Map<String, dynamic> request,
  }) {
    return _sendCommand('hub_submit_workspace', request);
  }

  Future<Map<String, dynamic>> hubVoteAgent({
    required String slug,
    required bool like,
  }) {
    return _sendCommand('hub_vote_agent', {'slug': slug, 'like': like});
  }

  Future<Map<String, dynamic>> hubVoteWorkspace({
    required String slug,
    required bool like,
  }) {
    return _sendCommand('hub_vote_workspace', {'slug': slug, 'like': like});
  }

  Future<Map<String, dynamic>> hubMyVotes({required String targetType}) {
    return _sendCommand('hub_my_votes', {'target_type': targetType});
  }

  Future<Map<String, dynamic>> hubSearchTags({
    required String query,
    String? tagType,
  }) {
    return _sendCommand('hub_search_tags', {
      'query': query,
      'tag_type': ?tagType,
    });
  }

  Future<Map<String, dynamic>> hubPopularTags({String? tagType}) {
    return _sendCommand('hub_popular_tags', {'tag_type': ?tagType});
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Disposes the client and closes the connection.
  void dispose() {
    connection.dispose();
  }
}
