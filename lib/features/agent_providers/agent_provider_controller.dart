// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/engine_client.dart';
import '../../models/commands/commands.dart';

part 'agent_provider_controller.g.dart';

@riverpod
class AgentProviderController extends _$AgentProviderController {
  @override
  Future<void> build() async {}

  EngineClient get _client => ref.read(engineClientProvider);

  Future<bool> createAgentProvider(Map<String, dynamic> request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(CreateAgentProvider(request: request)));
    if (state.hasError) {
      final message = state.error is EngineException
          ? (state.error as EngineException).message
          : 'Failed to create agent provider';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Agent provider created', type: ToastType.success);
    return true;
  }

  Future<bool> updateAgentProvider(
      String id, Map<String, dynamic> request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(UpdateAgentProvider(id: id, request: request)));
    if (state.hasError) {
      final message = state.error is EngineException
          ? (state.error as EngineException).message
          : 'Failed to update agent provider';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Agent provider updated', type: ToastType.success);
    return true;
  }

  Future<bool> deleteAgentProvider(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(DeleteAgentProvider(id: id)));
    if (state.hasError) {
      final message = state.error is EngineException
          ? (state.error as EngineException).message
          : 'Failed to delete agent provider';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Agent provider deleted', type: ToastType.success);
    return true;
  }

  Future<bool> updateAgentTemplate(String id, String name, String sourceUri) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(UpdateAgentTemplate(id: id, name: name, sourceUri: sourceUri)));
    if (state.hasError) {
      final message = state.error is EngineException
          ? (state.error as EngineException).message
          : 'Failed to update template';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Template updated', type: ToastType.success);
    return true;
  }

  Future<bool> deleteAgentTemplate(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _client.send(DeleteAgentTemplate(id: id)));
    if (state.hasError) {
      final message = state.error is EngineException
          ? (state.error as EngineException).message
          : 'Failed to delete template';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Template deleted', type: ToastType.success);
    return true;
  }
}
