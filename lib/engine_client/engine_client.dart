// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'engine_connection.dart';
import 'protocol/protocol.dart';

/// Exception thrown when the engine returns an error response to a command.
class EngineException implements Exception {
  final String code;
  final String message;

  const EngineException({required this.code, required this.message});

  @override
  String toString() => 'EngineException($code): $message';
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
  Future<Map<String, dynamic>> sendCommand(
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

  // ── Workspace Commands ────────────────────────────────────────────────

  /// Creates a new workspace and returns its ID.
  Future<Map<String, dynamic>> createWorkspace({
    required String name,
    required String projectPath,
    String? templateId,
  }) {
    return sendCommand('create_workspace', {
      'name': name,
      'project_path': projectPath,
      if (templateId != null) 'template_id': templateId,
    });
  }

  /// Launches a workspace container.
  Future<Map<String, dynamic>> launchWorkspace(String workspaceId) {
    return sendCommand('launch_workspace', {'id': workspaceId});
  }

  /// Stops a running workspace container.
  Future<Map<String, dynamic>> stopWorkspace(String workspaceId) {
    return sendCommand('stop_workspace', {'id': workspaceId});
  }

  /// Deletes a workspace by ID.
  Future<Map<String, dynamic>> deleteWorkspace(String workspaceId) {
    return sendCommand('delete_workspace', {'id': workspaceId});
  }

  // ── Agent Interaction Commands ────────────────────────────────────────

  /// Sends user input to a running agent instance.
  Future<Map<String, dynamic>> sendUserInputToAgent({
    required String runId,
    required String agentKey,
    required String content,
  }) {
    return sendCommand('send_user_input_to_agent', {
      'run_id': runId,
      'agent_key': agentKey,
      'content': content,
    });
  }

  /// Responds to an inquiry.
  Future<Map<String, dynamic>> respondToInquiry({
    required String inquiryId,
    required String response,
    int? choiceIndex,
  }) {
    return sendCommand('respond_to_inquiry', {
      'inquiry_id': inquiryId,
      'response': response,
      if (choiceIndex != null) 'choice_index': choiceIndex,
    });
  }

  // ── API Key Commands ──────────────────────────────────────────────────

  /// Creates a new API key.
  Future<Map<String, dynamic>> createApiKey({
    required String name,
    required String value,
    String? providerName,
  }) {
    return sendCommand('create_api_key', {
      'name': name,
      'value': value,
      if (providerName != null) 'provider_name': providerName,
    });
  }

  /// Deletes an API key by ID.
  Future<Map<String, dynamic>> deleteApiKey(String id) {
    return sendCommand('delete_api_key', {'id': id});
  }

  // ── Preference Commands ───────────────────────────────────────────────

  /// Gets a preference value by key.
  Future<Map<String, dynamic>> getPreference(String key) {
    return sendCommand('get_preference', {'key': key});
  }

  /// Sets a preference value.
  Future<Map<String, dynamic>> setPreference(String key, String value) {
    return sendCommand('set_preference', {'key': key, 'value': value});
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Disposes the client and closes the connection.
  void dispose() {
    connection.dispose();
  }
}
