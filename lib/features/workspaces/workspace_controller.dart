// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/engine_client.dart';
import '../../models/commands/agent.dart';
import '../../models/commands/workspace.dart';

part 'workspace_controller.g.dart';

@riverpod
class WorkspaceController extends _$WorkspaceController {
  @override
  Future<void> build() async {}

  EngineClient get _client => ref.read(engineClientProvider);

  Future<bool> createWorkspace({
    required String projectPath,
    required String configYaml,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(CreateWorkspace(
              projectPath: projectPath,
              configYaml: configYaml,
            )));
    if (state.hasError) {
      final error = state.error;
      final message = switch (error) {
        EngineException(:final message) => message,
        FormatException() => 'Invalid config: ${error.message}',
        StateError() => error.message,
        FileSystemException() =>
          'File system error at "${error.path ?? 'unknown'}": ${error.message}'
              '\nCheck that the path exists and is accessible.',
        _ => 'Failed to create workspace: $error',
      };
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Workspace created', type: ToastType.success);
    return true;
  }

  Future<bool> deleteWorkspace(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(DeleteWorkspace(id: id)));
    if (state.hasError) {
      toast('Failed to delete workspace', type: ToastType.error);
      return false;
    }
    toast('Workspace deleted', type: ToastType.success);
    return true;
  }

  Future<bool> launchWorkspace(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(LaunchWorkspace(id: id)));
    if (state.hasError) {
      toast('Failed to launch workspace: ${state.error}',
          type: ToastType.error);
      return false;
    }
    toast('Workspace started', type: ToastType.success);
    return true;
  }

  Future<bool> stopWorkspace(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(StopWorkspace(id: id)));
    if (state.hasError) {
      toast('Failed to stop workspace: ${state.error}',
          type: ToastType.error);
      return false;
    }
    toast('Workspace stopped', type: ToastType.success);
    return true;
  }

  Future<bool> restartWorkspace(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.send(StopWorkspace(id: id));
      await _client.send(LaunchWorkspace(id: id));
    });
    if (state.hasError) {
      toast('Failed to restart workspace: ${state.error}',
          type: ToastType.error);
      return false;
    }
    toast('Workspace restarted', type: ToastType.success);
    return true;
  }

  Future<bool> respondToInquiry(
    String inquiryId, {
    String? responseText,
    int? responseSuggestionIndex,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _client.send(RespondToInquiry(
        inquiryId: inquiryId,
        response: responseText ?? '',
        choiceIndex: responseSuggestionIndex,
      )),
    );
    if (state.hasError) {
      toast('Failed to respond to inquiry', type: ToastType.error);
      return false;
    }
    toast('Response sent', type: ToastType.success);
    return true;
  }

  /// Sends user input to a specific agent instance. Does not set loading state
  /// so the input field feels instant.
  Future<bool> sendUserInput(
    String runId,
    String instanceId,
    String text,
  ) async {
    try {
      await _client.send(SendAgentInput(
          runId: runId, instanceId: instanceId, text: text));
      return true;
    } catch (e) {
      toast('Failed to send message: $e', type: ToastType.error);
      return false;
    }
  }

  /// Sends an interrupt signal to a running agent instance.
  // TODO: InterruptInstance now requires agentKey — callers need to provide it.
  Future<bool> interruptInstance(
    String runId,
    String instanceId,
  ) async {
    try {
      await _client.sendCommand('interrupt_instance', {
        'run_id': runId,
        'instance_id': instanceId,
      });
      return true;
    } catch (e) {
      toast('Failed to interrupt agent: $e', type: ToastType.error);
      return false;
    }
  }
}
