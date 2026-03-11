// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$engineControllerHash() => r'44bcdba17aef7ce79cc5e37d2ff42036eb12621c';

/// Controller for user-initiated Docker operations on the Engine screen.
///
/// Follows the [ProviderController] pattern: `@riverpod` AsyncNotifier,
/// `AsyncValue.guard()` for simple operations, manual state management
/// for streamed operations.
///
/// Copied from [EngineController].
@ProviderFor(EngineController)
final engineControllerProvider =
    AutoDisposeAsyncNotifierProvider<EngineController, void>.internal(
      EngineController.new,
      name: r'engineControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$engineControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EngineController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
