// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';

part 'agent_provider_controller.g.dart';

@riverpod
class AgentProviderController extends _$AgentProviderController {
  @override
  FutureOr<void> build() {}

  RustSdk get _sdk => ref.read(sdkProvider);

  Future<bool> createAgentProvider(
      CreateAgentProviderRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _sdk.createAgentProvider(request: request));
    if (state.hasError) {
      final message = state.error is StateError
          ? (state.error as StateError).message
          : 'Failed to create agent provider';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Agent provider created', type: ToastType.success);
    return true;
  }

  Future<bool> updateAgentProvider(
      String id, UpdateAgentProviderRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _sdk.updateAgentProvider(id: id, request: request));
    if (state.hasError) {
      final message = state.error is StateError
          ? (state.error as StateError).message
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
        () => _sdk.deleteAgentProvider(id: id));
    if (state.hasError) {
      final message = state.error is StateError
          ? (state.error as StateError).message
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
        () => _sdk.updateAgentTemplate(id: id, name: name, sourceUri: sourceUri));
    if (state.hasError) {
      final message = state.error is StateError
          ? (state.error as StateError).message
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
        () => _sdk.deleteAgentTemplate(id: id));
    if (state.hasError) {
      final message = state.error is StateError
          ? (state.error as StateError).message
          : 'Failed to delete template';
      toast(message, type: ToastType.error);
      return false;
    }
    toast('Template deleted', type: ToastType.success);
    return true;
  }
}
