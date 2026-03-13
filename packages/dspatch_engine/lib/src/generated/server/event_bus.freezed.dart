// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_bus.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SdkEvent {
  String get workspaceId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SdkEventCopyWith<SdkEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SdkEventCopyWith<$Res> {
  factory $SdkEventCopyWith(SdkEvent value, $Res Function(SdkEvent) then) =
      _$SdkEventCopyWithImpl<$Res, SdkEvent>;
  @useResult
  $Res call({String workspaceId});
}

/// @nodoc
class _$SdkEventCopyWithImpl<$Res, $Val extends SdkEvent>
    implements $SdkEventCopyWith<$Res> {
  _$SdkEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
  }) {
    return _then(_value.copyWith(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SdkEvent_WorkspaceRunStartedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_WorkspaceRunStartedImplCopyWith(
          _$SdkEvent_WorkspaceRunStartedImpl value,
          $Res Function(_$SdkEvent_WorkspaceRunStartedImpl) then) =
      __$$SdkEvent_WorkspaceRunStartedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String runId});
}

/// @nodoc
class __$$SdkEvent_WorkspaceRunStartedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_WorkspaceRunStartedImpl>
    implements _$$SdkEvent_WorkspaceRunStartedImplCopyWith<$Res> {
  __$$SdkEvent_WorkspaceRunStartedImplCopyWithImpl(
      _$SdkEvent_WorkspaceRunStartedImpl _value,
      $Res Function(_$SdkEvent_WorkspaceRunStartedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? runId = null,
  }) {
    return _then(_$SdkEvent_WorkspaceRunStartedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_WorkspaceRunStartedImpl extends SdkEvent_WorkspaceRunStarted {
  const _$SdkEvent_WorkspaceRunStartedImpl(
      {required this.workspaceId, required this.runId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String runId;

  @override
  String toString() {
    return 'SdkEvent.workspaceRunStarted(workspaceId: $workspaceId, runId: $runId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_WorkspaceRunStartedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.runId, runId) || other.runId == runId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, runId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_WorkspaceRunStartedImplCopyWith<
          _$SdkEvent_WorkspaceRunStartedImpl>
      get copyWith => __$$SdkEvent_WorkspaceRunStartedImplCopyWithImpl<
          _$SdkEvent_WorkspaceRunStartedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return workspaceRunStarted(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return workspaceRunStarted?.call(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunStarted != null) {
      return workspaceRunStarted(workspaceId, runId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return workspaceRunStarted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return workspaceRunStarted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunStarted != null) {
      return workspaceRunStarted(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_WorkspaceRunStarted extends SdkEvent {
  const factory SdkEvent_WorkspaceRunStarted(
      {required final String workspaceId,
      required final String runId}) = _$SdkEvent_WorkspaceRunStartedImpl;
  const SdkEvent_WorkspaceRunStarted._() : super._();

  @override
  String get workspaceId;
  String get runId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_WorkspaceRunStartedImplCopyWith<
          _$SdkEvent_WorkspaceRunStartedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_WorkspaceRunStoppedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_WorkspaceRunStoppedImplCopyWith(
          _$SdkEvent_WorkspaceRunStoppedImpl value,
          $Res Function(_$SdkEvent_WorkspaceRunStoppedImpl) then) =
      __$$SdkEvent_WorkspaceRunStoppedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String runId});
}

/// @nodoc
class __$$SdkEvent_WorkspaceRunStoppedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_WorkspaceRunStoppedImpl>
    implements _$$SdkEvent_WorkspaceRunStoppedImplCopyWith<$Res> {
  __$$SdkEvent_WorkspaceRunStoppedImplCopyWithImpl(
      _$SdkEvent_WorkspaceRunStoppedImpl _value,
      $Res Function(_$SdkEvent_WorkspaceRunStoppedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? runId = null,
  }) {
    return _then(_$SdkEvent_WorkspaceRunStoppedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_WorkspaceRunStoppedImpl extends SdkEvent_WorkspaceRunStopped {
  const _$SdkEvent_WorkspaceRunStoppedImpl(
      {required this.workspaceId, required this.runId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String runId;

  @override
  String toString() {
    return 'SdkEvent.workspaceRunStopped(workspaceId: $workspaceId, runId: $runId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_WorkspaceRunStoppedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.runId, runId) || other.runId == runId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, runId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_WorkspaceRunStoppedImplCopyWith<
          _$SdkEvent_WorkspaceRunStoppedImpl>
      get copyWith => __$$SdkEvent_WorkspaceRunStoppedImplCopyWithImpl<
          _$SdkEvent_WorkspaceRunStoppedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return workspaceRunStopped(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return workspaceRunStopped?.call(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunStopped != null) {
      return workspaceRunStopped(workspaceId, runId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return workspaceRunStopped(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return workspaceRunStopped?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunStopped != null) {
      return workspaceRunStopped(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_WorkspaceRunStopped extends SdkEvent {
  const factory SdkEvent_WorkspaceRunStopped(
      {required final String workspaceId,
      required final String runId}) = _$SdkEvent_WorkspaceRunStoppedImpl;
  const SdkEvent_WorkspaceRunStopped._() : super._();

  @override
  String get workspaceId;
  String get runId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_WorkspaceRunStoppedImplCopyWith<
          _$SdkEvent_WorkspaceRunStoppedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_WorkspaceRunFailedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_WorkspaceRunFailedImplCopyWith(
          _$SdkEvent_WorkspaceRunFailedImpl value,
          $Res Function(_$SdkEvent_WorkspaceRunFailedImpl) then) =
      __$$SdkEvent_WorkspaceRunFailedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String runId});
}

/// @nodoc
class __$$SdkEvent_WorkspaceRunFailedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_WorkspaceRunFailedImpl>
    implements _$$SdkEvent_WorkspaceRunFailedImplCopyWith<$Res> {
  __$$SdkEvent_WorkspaceRunFailedImplCopyWithImpl(
      _$SdkEvent_WorkspaceRunFailedImpl _value,
      $Res Function(_$SdkEvent_WorkspaceRunFailedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? runId = null,
  }) {
    return _then(_$SdkEvent_WorkspaceRunFailedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_WorkspaceRunFailedImpl extends SdkEvent_WorkspaceRunFailed {
  const _$SdkEvent_WorkspaceRunFailedImpl(
      {required this.workspaceId, required this.runId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String runId;

  @override
  String toString() {
    return 'SdkEvent.workspaceRunFailed(workspaceId: $workspaceId, runId: $runId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_WorkspaceRunFailedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.runId, runId) || other.runId == runId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, runId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_WorkspaceRunFailedImplCopyWith<_$SdkEvent_WorkspaceRunFailedImpl>
      get copyWith => __$$SdkEvent_WorkspaceRunFailedImplCopyWithImpl<
          _$SdkEvent_WorkspaceRunFailedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return workspaceRunFailed(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return workspaceRunFailed?.call(workspaceId, runId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunFailed != null) {
      return workspaceRunFailed(workspaceId, runId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return workspaceRunFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return workspaceRunFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (workspaceRunFailed != null) {
      return workspaceRunFailed(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_WorkspaceRunFailed extends SdkEvent {
  const factory SdkEvent_WorkspaceRunFailed(
      {required final String workspaceId,
      required final String runId}) = _$SdkEvent_WorkspaceRunFailedImpl;
  const SdkEvent_WorkspaceRunFailed._() : super._();

  @override
  String get workspaceId;
  String get runId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_WorkspaceRunFailedImplCopyWith<_$SdkEvent_WorkspaceRunFailedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_AgentConnectedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_AgentConnectedImplCopyWith(
          _$SdkEvent_AgentConnectedImpl value,
          $Res Function(_$SdkEvent_AgentConnectedImpl) then) =
      __$$SdkEvent_AgentConnectedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String agentKey});
}

/// @nodoc
class __$$SdkEvent_AgentConnectedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_AgentConnectedImpl>
    implements _$$SdkEvent_AgentConnectedImplCopyWith<$Res> {
  __$$SdkEvent_AgentConnectedImplCopyWithImpl(
      _$SdkEvent_AgentConnectedImpl _value,
      $Res Function(_$SdkEvent_AgentConnectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
  }) {
    return _then(_$SdkEvent_AgentConnectedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_AgentConnectedImpl extends SdkEvent_AgentConnected {
  const _$SdkEvent_AgentConnectedImpl(
      {required this.workspaceId, required this.agentKey})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;

  @override
  String toString() {
    return 'SdkEvent.agentConnected(workspaceId: $workspaceId, agentKey: $agentKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_AgentConnectedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, agentKey);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_AgentConnectedImplCopyWith<_$SdkEvent_AgentConnectedImpl>
      get copyWith => __$$SdkEvent_AgentConnectedImplCopyWithImpl<
          _$SdkEvent_AgentConnectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return agentConnected(workspaceId, agentKey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return agentConnected?.call(workspaceId, agentKey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (agentConnected != null) {
      return agentConnected(workspaceId, agentKey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return agentConnected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return agentConnected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (agentConnected != null) {
      return agentConnected(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_AgentConnected extends SdkEvent {
  const factory SdkEvent_AgentConnected(
      {required final String workspaceId,
      required final String agentKey}) = _$SdkEvent_AgentConnectedImpl;
  const SdkEvent_AgentConnected._() : super._();

  @override
  String get workspaceId;
  String get agentKey;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_AgentConnectedImplCopyWith<_$SdkEvent_AgentConnectedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_AgentDisconnectedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_AgentDisconnectedImplCopyWith(
          _$SdkEvent_AgentDisconnectedImpl value,
          $Res Function(_$SdkEvent_AgentDisconnectedImpl) then) =
      __$$SdkEvent_AgentDisconnectedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String agentKey});
}

/// @nodoc
class __$$SdkEvent_AgentDisconnectedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_AgentDisconnectedImpl>
    implements _$$SdkEvent_AgentDisconnectedImplCopyWith<$Res> {
  __$$SdkEvent_AgentDisconnectedImplCopyWithImpl(
      _$SdkEvent_AgentDisconnectedImpl _value,
      $Res Function(_$SdkEvent_AgentDisconnectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
  }) {
    return _then(_$SdkEvent_AgentDisconnectedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_AgentDisconnectedImpl extends SdkEvent_AgentDisconnected {
  const _$SdkEvent_AgentDisconnectedImpl(
      {required this.workspaceId, required this.agentKey})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;

  @override
  String toString() {
    return 'SdkEvent.agentDisconnected(workspaceId: $workspaceId, agentKey: $agentKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_AgentDisconnectedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, agentKey);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_AgentDisconnectedImplCopyWith<_$SdkEvent_AgentDisconnectedImpl>
      get copyWith => __$$SdkEvent_AgentDisconnectedImplCopyWithImpl<
          _$SdkEvent_AgentDisconnectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return agentDisconnected(workspaceId, agentKey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return agentDisconnected?.call(workspaceId, agentKey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (agentDisconnected != null) {
      return agentDisconnected(workspaceId, agentKey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return agentDisconnected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return agentDisconnected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (agentDisconnected != null) {
      return agentDisconnected(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_AgentDisconnected extends SdkEvent {
  const factory SdkEvent_AgentDisconnected(
      {required final String workspaceId,
      required final String agentKey}) = _$SdkEvent_AgentDisconnectedImpl;
  const SdkEvent_AgentDisconnected._() : super._();

  @override
  String get workspaceId;
  String get agentKey;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_AgentDisconnectedImplCopyWith<_$SdkEvent_AgentDisconnectedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_InstanceCreatedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_InstanceCreatedImplCopyWith(
          _$SdkEvent_InstanceCreatedImpl value,
          $Res Function(_$SdkEvent_InstanceCreatedImpl) then) =
      __$$SdkEvent_InstanceCreatedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String agentKey, String instanceId});
}

/// @nodoc
class __$$SdkEvent_InstanceCreatedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_InstanceCreatedImpl>
    implements _$$SdkEvent_InstanceCreatedImplCopyWith<$Res> {
  __$$SdkEvent_InstanceCreatedImplCopyWithImpl(
      _$SdkEvent_InstanceCreatedImpl _value,
      $Res Function(_$SdkEvent_InstanceCreatedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
    Object? instanceId = null,
  }) {
    return _then(_$SdkEvent_InstanceCreatedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
      instanceId: null == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_InstanceCreatedImpl extends SdkEvent_InstanceCreated {
  const _$SdkEvent_InstanceCreatedImpl(
      {required this.workspaceId,
      required this.agentKey,
      required this.instanceId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;
  @override
  final String instanceId;

  @override
  String toString() {
    return 'SdkEvent.instanceCreated(workspaceId: $workspaceId, agentKey: $agentKey, instanceId: $instanceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_InstanceCreatedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey) &&
            (identical(other.instanceId, instanceId) ||
                other.instanceId == instanceId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, workspaceId, agentKey, instanceId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_InstanceCreatedImplCopyWith<_$SdkEvent_InstanceCreatedImpl>
      get copyWith => __$$SdkEvent_InstanceCreatedImplCopyWithImpl<
          _$SdkEvent_InstanceCreatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return instanceCreated(workspaceId, agentKey, instanceId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return instanceCreated?.call(workspaceId, agentKey, instanceId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceCreated != null) {
      return instanceCreated(workspaceId, agentKey, instanceId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return instanceCreated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return instanceCreated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceCreated != null) {
      return instanceCreated(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_InstanceCreated extends SdkEvent {
  const factory SdkEvent_InstanceCreated(
      {required final String workspaceId,
      required final String agentKey,
      required final String instanceId}) = _$SdkEvent_InstanceCreatedImpl;
  const SdkEvent_InstanceCreated._() : super._();

  @override
  String get workspaceId;
  String get agentKey;
  String get instanceId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_InstanceCreatedImplCopyWith<_$SdkEvent_InstanceCreatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_InstanceStateChangedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_InstanceStateChangedImplCopyWith(
          _$SdkEvent_InstanceStateChangedImpl value,
          $Res Function(_$SdkEvent_InstanceStateChangedImpl) then) =
      __$$SdkEvent_InstanceStateChangedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String workspaceId,
      String agentKey,
      String instanceId,
      String oldState,
      String newState});
}

/// @nodoc
class __$$SdkEvent_InstanceStateChangedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_InstanceStateChangedImpl>
    implements _$$SdkEvent_InstanceStateChangedImplCopyWith<$Res> {
  __$$SdkEvent_InstanceStateChangedImplCopyWithImpl(
      _$SdkEvent_InstanceStateChangedImpl _value,
      $Res Function(_$SdkEvent_InstanceStateChangedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
    Object? instanceId = null,
    Object? oldState = null,
    Object? newState = null,
  }) {
    return _then(_$SdkEvent_InstanceStateChangedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
      instanceId: null == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String,
      oldState: null == oldState
          ? _value.oldState
          : oldState // ignore: cast_nullable_to_non_nullable
              as String,
      newState: null == newState
          ? _value.newState
          : newState // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_InstanceStateChangedImpl
    extends SdkEvent_InstanceStateChanged {
  const _$SdkEvent_InstanceStateChangedImpl(
      {required this.workspaceId,
      required this.agentKey,
      required this.instanceId,
      required this.oldState,
      required this.newState})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;
  @override
  final String instanceId;
  @override
  final String oldState;
  @override
  final String newState;

  @override
  String toString() {
    return 'SdkEvent.instanceStateChanged(workspaceId: $workspaceId, agentKey: $agentKey, instanceId: $instanceId, oldState: $oldState, newState: $newState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_InstanceStateChangedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey) &&
            (identical(other.instanceId, instanceId) ||
                other.instanceId == instanceId) &&
            (identical(other.oldState, oldState) ||
                other.oldState == oldState) &&
            (identical(other.newState, newState) ||
                other.newState == newState));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, workspaceId, agentKey, instanceId, oldState, newState);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_InstanceStateChangedImplCopyWith<
          _$SdkEvent_InstanceStateChangedImpl>
      get copyWith => __$$SdkEvent_InstanceStateChangedImplCopyWithImpl<
          _$SdkEvent_InstanceStateChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return instanceStateChanged(
        workspaceId, agentKey, instanceId, oldState, newState);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return instanceStateChanged?.call(
        workspaceId, agentKey, instanceId, oldState, newState);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceStateChanged != null) {
      return instanceStateChanged(
          workspaceId, agentKey, instanceId, oldState, newState);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return instanceStateChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return instanceStateChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceStateChanged != null) {
      return instanceStateChanged(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_InstanceStateChanged extends SdkEvent {
  const factory SdkEvent_InstanceStateChanged(
      {required final String workspaceId,
      required final String agentKey,
      required final String instanceId,
      required final String oldState,
      required final String newState}) = _$SdkEvent_InstanceStateChangedImpl;
  const SdkEvent_InstanceStateChanged._() : super._();

  @override
  String get workspaceId;
  String get agentKey;
  String get instanceId;
  String get oldState;
  String get newState;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_InstanceStateChangedImplCopyWith<
          _$SdkEvent_InstanceStateChangedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_InstanceGoneImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_InstanceGoneImplCopyWith(
          _$SdkEvent_InstanceGoneImpl value,
          $Res Function(_$SdkEvent_InstanceGoneImpl) then) =
      __$$SdkEvent_InstanceGoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String agentKey, String instanceId});
}

/// @nodoc
class __$$SdkEvent_InstanceGoneImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_InstanceGoneImpl>
    implements _$$SdkEvent_InstanceGoneImplCopyWith<$Res> {
  __$$SdkEvent_InstanceGoneImplCopyWithImpl(_$SdkEvent_InstanceGoneImpl _value,
      $Res Function(_$SdkEvent_InstanceGoneImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
    Object? instanceId = null,
  }) {
    return _then(_$SdkEvent_InstanceGoneImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
      instanceId: null == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_InstanceGoneImpl extends SdkEvent_InstanceGone {
  const _$SdkEvent_InstanceGoneImpl(
      {required this.workspaceId,
      required this.agentKey,
      required this.instanceId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;
  @override
  final String instanceId;

  @override
  String toString() {
    return 'SdkEvent.instanceGone(workspaceId: $workspaceId, agentKey: $agentKey, instanceId: $instanceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_InstanceGoneImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey) &&
            (identical(other.instanceId, instanceId) ||
                other.instanceId == instanceId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, workspaceId, agentKey, instanceId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_InstanceGoneImplCopyWith<_$SdkEvent_InstanceGoneImpl>
      get copyWith => __$$SdkEvent_InstanceGoneImplCopyWithImpl<
          _$SdkEvent_InstanceGoneImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return instanceGone(workspaceId, agentKey, instanceId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return instanceGone?.call(workspaceId, agentKey, instanceId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceGone != null) {
      return instanceGone(workspaceId, agentKey, instanceId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return instanceGone(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return instanceGone?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (instanceGone != null) {
      return instanceGone(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_InstanceGone extends SdkEvent {
  const factory SdkEvent_InstanceGone(
      {required final String workspaceId,
      required final String agentKey,
      required final String instanceId}) = _$SdkEvent_InstanceGoneImpl;
  const SdkEvent_InstanceGone._() : super._();

  @override
  String get workspaceId;
  String get agentKey;
  String get instanceId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_InstanceGoneImplCopyWith<_$SdkEvent_InstanceGoneImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_InquiryCreatedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_InquiryCreatedImplCopyWith(
          _$SdkEvent_InquiryCreatedImpl value,
          $Res Function(_$SdkEvent_InquiryCreatedImpl) then) =
      __$$SdkEvent_InquiryCreatedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String workspaceId, String agentKey, String inquiryId, String priority});
}

/// @nodoc
class __$$SdkEvent_InquiryCreatedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_InquiryCreatedImpl>
    implements _$$SdkEvent_InquiryCreatedImplCopyWith<$Res> {
  __$$SdkEvent_InquiryCreatedImplCopyWithImpl(
      _$SdkEvent_InquiryCreatedImpl _value,
      $Res Function(_$SdkEvent_InquiryCreatedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
    Object? inquiryId = null,
    Object? priority = null,
  }) {
    return _then(_$SdkEvent_InquiryCreatedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
      inquiryId: null == inquiryId
          ? _value.inquiryId
          : inquiryId // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_InquiryCreatedImpl extends SdkEvent_InquiryCreated {
  const _$SdkEvent_InquiryCreatedImpl(
      {required this.workspaceId,
      required this.agentKey,
      required this.inquiryId,
      required this.priority})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;
  @override
  final String inquiryId;
  @override
  final String priority;

  @override
  String toString() {
    return 'SdkEvent.inquiryCreated(workspaceId: $workspaceId, agentKey: $agentKey, inquiryId: $inquiryId, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_InquiryCreatedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey) &&
            (identical(other.inquiryId, inquiryId) ||
                other.inquiryId == inquiryId) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, workspaceId, agentKey, inquiryId, priority);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_InquiryCreatedImplCopyWith<_$SdkEvent_InquiryCreatedImpl>
      get copyWith => __$$SdkEvent_InquiryCreatedImplCopyWithImpl<
          _$SdkEvent_InquiryCreatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return inquiryCreated(workspaceId, agentKey, inquiryId, priority);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return inquiryCreated?.call(workspaceId, agentKey, inquiryId, priority);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (inquiryCreated != null) {
      return inquiryCreated(workspaceId, agentKey, inquiryId, priority);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return inquiryCreated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return inquiryCreated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (inquiryCreated != null) {
      return inquiryCreated(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_InquiryCreated extends SdkEvent {
  const factory SdkEvent_InquiryCreated(
      {required final String workspaceId,
      required final String agentKey,
      required final String inquiryId,
      required final String priority}) = _$SdkEvent_InquiryCreatedImpl;
  const SdkEvent_InquiryCreated._() : super._();

  @override
  String get workspaceId;
  String get agentKey;
  String get inquiryId;
  String get priority;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_InquiryCreatedImplCopyWith<_$SdkEvent_InquiryCreatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_InquiryResolvedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_InquiryResolvedImplCopyWith(
          _$SdkEvent_InquiryResolvedImpl value,
          $Res Function(_$SdkEvent_InquiryResolvedImpl) then) =
      __$$SdkEvent_InquiryResolvedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String inquiryId});
}

/// @nodoc
class __$$SdkEvent_InquiryResolvedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_InquiryResolvedImpl>
    implements _$$SdkEvent_InquiryResolvedImplCopyWith<$Res> {
  __$$SdkEvent_InquiryResolvedImplCopyWithImpl(
      _$SdkEvent_InquiryResolvedImpl _value,
      $Res Function(_$SdkEvent_InquiryResolvedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? inquiryId = null,
  }) {
    return _then(_$SdkEvent_InquiryResolvedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      inquiryId: null == inquiryId
          ? _value.inquiryId
          : inquiryId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_InquiryResolvedImpl extends SdkEvent_InquiryResolved {
  const _$SdkEvent_InquiryResolvedImpl(
      {required this.workspaceId, required this.inquiryId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String inquiryId;

  @override
  String toString() {
    return 'SdkEvent.inquiryResolved(workspaceId: $workspaceId, inquiryId: $inquiryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_InquiryResolvedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.inquiryId, inquiryId) ||
                other.inquiryId == inquiryId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, inquiryId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_InquiryResolvedImplCopyWith<_$SdkEvent_InquiryResolvedImpl>
      get copyWith => __$$SdkEvent_InquiryResolvedImplCopyWithImpl<
          _$SdkEvent_InquiryResolvedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return inquiryResolved(workspaceId, inquiryId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return inquiryResolved?.call(workspaceId, inquiryId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (inquiryResolved != null) {
      return inquiryResolved(workspaceId, inquiryId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return inquiryResolved(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return inquiryResolved?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (inquiryResolved != null) {
      return inquiryResolved(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_InquiryResolved extends SdkEvent {
  const factory SdkEvent_InquiryResolved(
      {required final String workspaceId,
      required final String inquiryId}) = _$SdkEvent_InquiryResolvedImpl;
  const SdkEvent_InquiryResolved._() : super._();

  @override
  String get workspaceId;
  String get inquiryId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_InquiryResolvedImplCopyWith<_$SdkEvent_InquiryResolvedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_TurnCompletedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_TurnCompletedImplCopyWith(
          _$SdkEvent_TurnCompletedImpl value,
          $Res Function(_$SdkEvent_TurnCompletedImpl) then) =
      __$$SdkEvent_TurnCompletedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String workspaceId, String agentKey, String instanceId, String turnId});
}

/// @nodoc
class __$$SdkEvent_TurnCompletedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_TurnCompletedImpl>
    implements _$$SdkEvent_TurnCompletedImplCopyWith<$Res> {
  __$$SdkEvent_TurnCompletedImplCopyWithImpl(
      _$SdkEvent_TurnCompletedImpl _value,
      $Res Function(_$SdkEvent_TurnCompletedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? agentKey = null,
    Object? instanceId = null,
    Object? turnId = null,
  }) {
    return _then(_$SdkEvent_TurnCompletedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      agentKey: null == agentKey
          ? _value.agentKey
          : agentKey // ignore: cast_nullable_to_non_nullable
              as String,
      instanceId: null == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String,
      turnId: null == turnId
          ? _value.turnId
          : turnId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_TurnCompletedImpl extends SdkEvent_TurnCompleted {
  const _$SdkEvent_TurnCompletedImpl(
      {required this.workspaceId,
      required this.agentKey,
      required this.instanceId,
      required this.turnId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String agentKey;
  @override
  final String instanceId;
  @override
  final String turnId;

  @override
  String toString() {
    return 'SdkEvent.turnCompleted(workspaceId: $workspaceId, agentKey: $agentKey, instanceId: $instanceId, turnId: $turnId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_TurnCompletedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.agentKey, agentKey) ||
                other.agentKey == agentKey) &&
            (identical(other.instanceId, instanceId) ||
                other.instanceId == instanceId) &&
            (identical(other.turnId, turnId) || other.turnId == turnId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, workspaceId, agentKey, instanceId, turnId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_TurnCompletedImplCopyWith<_$SdkEvent_TurnCompletedImpl>
      get copyWith => __$$SdkEvent_TurnCompletedImplCopyWithImpl<
          _$SdkEvent_TurnCompletedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return turnCompleted(workspaceId, agentKey, instanceId, turnId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return turnCompleted?.call(workspaceId, agentKey, instanceId, turnId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (turnCompleted != null) {
      return turnCompleted(workspaceId, agentKey, instanceId, turnId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return turnCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return turnCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (turnCompleted != null) {
      return turnCompleted(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_TurnCompleted extends SdkEvent {
  const factory SdkEvent_TurnCompleted(
      {required final String workspaceId,
      required final String agentKey,
      required final String instanceId,
      required final String turnId}) = _$SdkEvent_TurnCompletedImpl;
  const SdkEvent_TurnCompleted._() : super._();

  @override
  String get workspaceId;
  String get agentKey;
  String get instanceId;
  String get turnId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_TurnCompletedImplCopyWith<_$SdkEvent_TurnCompletedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SdkEvent_ChainCompletedImplCopyWith<$Res>
    implements $SdkEventCopyWith<$Res> {
  factory _$$SdkEvent_ChainCompletedImplCopyWith(
          _$SdkEvent_ChainCompletedImpl value,
          $Res Function(_$SdkEvent_ChainCompletedImpl) then) =
      __$$SdkEvent_ChainCompletedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String workspaceId, String requestId});
}

/// @nodoc
class __$$SdkEvent_ChainCompletedImplCopyWithImpl<$Res>
    extends _$SdkEventCopyWithImpl<$Res, _$SdkEvent_ChainCompletedImpl>
    implements _$$SdkEvent_ChainCompletedImplCopyWith<$Res> {
  __$$SdkEvent_ChainCompletedImplCopyWithImpl(
      _$SdkEvent_ChainCompletedImpl _value,
      $Res Function(_$SdkEvent_ChainCompletedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspaceId = null,
    Object? requestId = null,
  }) {
    return _then(_$SdkEvent_ChainCompletedImpl(
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      requestId: null == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SdkEvent_ChainCompletedImpl extends SdkEvent_ChainCompleted {
  const _$SdkEvent_ChainCompletedImpl(
      {required this.workspaceId, required this.requestId})
      : super._();

  @override
  final String workspaceId;
  @override
  final String requestId;

  @override
  String toString() {
    return 'SdkEvent.chainCompleted(workspaceId: $workspaceId, requestId: $requestId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdkEvent_ChainCompletedImpl &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workspaceId, requestId);

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdkEvent_ChainCompletedImplCopyWith<_$SdkEvent_ChainCompletedImpl>
      get copyWith => __$$SdkEvent_ChainCompletedImplCopyWithImpl<
          _$SdkEvent_ChainCompletedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String workspaceId, String runId)
        workspaceRunStarted,
    required TResult Function(String workspaceId, String runId)
        workspaceRunStopped,
    required TResult Function(String workspaceId, String runId)
        workspaceRunFailed,
    required TResult Function(String workspaceId, String agentKey)
        agentConnected,
    required TResult Function(String workspaceId, String agentKey)
        agentDisconnected,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceCreated,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String oldState, String newState)
        instanceStateChanged,
    required TResult Function(
            String workspaceId, String agentKey, String instanceId)
        instanceGone,
    required TResult Function(String workspaceId, String agentKey,
            String inquiryId, String priority)
        inquiryCreated,
    required TResult Function(String workspaceId, String inquiryId)
        inquiryResolved,
    required TResult Function(String workspaceId, String agentKey,
            String instanceId, String turnId)
        turnCompleted,
    required TResult Function(String workspaceId, String requestId)
        chainCompleted,
  }) {
    return chainCompleted(workspaceId, requestId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult? Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult? Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult? Function(String workspaceId, String agentKey)? agentConnected,
    TResult? Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult? Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult? Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult? Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult? Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult? Function(String workspaceId, String requestId)? chainCompleted,
  }) {
    return chainCompleted?.call(workspaceId, requestId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String workspaceId, String runId)? workspaceRunStarted,
    TResult Function(String workspaceId, String runId)? workspaceRunStopped,
    TResult Function(String workspaceId, String runId)? workspaceRunFailed,
    TResult Function(String workspaceId, String agentKey)? agentConnected,
    TResult Function(String workspaceId, String agentKey)? agentDisconnected,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceCreated,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String oldState, String newState)?
        instanceStateChanged,
    TResult Function(String workspaceId, String agentKey, String instanceId)?
        instanceGone,
    TResult Function(String workspaceId, String agentKey, String inquiryId,
            String priority)?
        inquiryCreated,
    TResult Function(String workspaceId, String inquiryId)? inquiryResolved,
    TResult Function(String workspaceId, String agentKey, String instanceId,
            String turnId)?
        turnCompleted,
    TResult Function(String workspaceId, String requestId)? chainCompleted,
    required TResult orElse(),
  }) {
    if (chainCompleted != null) {
      return chainCompleted(workspaceId, requestId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SdkEvent_WorkspaceRunStarted value)
        workspaceRunStarted,
    required TResult Function(SdkEvent_WorkspaceRunStopped value)
        workspaceRunStopped,
    required TResult Function(SdkEvent_WorkspaceRunFailed value)
        workspaceRunFailed,
    required TResult Function(SdkEvent_AgentConnected value) agentConnected,
    required TResult Function(SdkEvent_AgentDisconnected value)
        agentDisconnected,
    required TResult Function(SdkEvent_InstanceCreated value) instanceCreated,
    required TResult Function(SdkEvent_InstanceStateChanged value)
        instanceStateChanged,
    required TResult Function(SdkEvent_InstanceGone value) instanceGone,
    required TResult Function(SdkEvent_InquiryCreated value) inquiryCreated,
    required TResult Function(SdkEvent_InquiryResolved value) inquiryResolved,
    required TResult Function(SdkEvent_TurnCompleted value) turnCompleted,
    required TResult Function(SdkEvent_ChainCompleted value) chainCompleted,
  }) {
    return chainCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult? Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult? Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult? Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult? Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult? Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult? Function(SdkEvent_InstanceStateChanged value)?
        instanceStateChanged,
    TResult? Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult? Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult? Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult? Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult? Function(SdkEvent_ChainCompleted value)? chainCompleted,
  }) {
    return chainCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SdkEvent_WorkspaceRunStarted value)? workspaceRunStarted,
    TResult Function(SdkEvent_WorkspaceRunStopped value)? workspaceRunStopped,
    TResult Function(SdkEvent_WorkspaceRunFailed value)? workspaceRunFailed,
    TResult Function(SdkEvent_AgentConnected value)? agentConnected,
    TResult Function(SdkEvent_AgentDisconnected value)? agentDisconnected,
    TResult Function(SdkEvent_InstanceCreated value)? instanceCreated,
    TResult Function(SdkEvent_InstanceStateChanged value)? instanceStateChanged,
    TResult Function(SdkEvent_InstanceGone value)? instanceGone,
    TResult Function(SdkEvent_InquiryCreated value)? inquiryCreated,
    TResult Function(SdkEvent_InquiryResolved value)? inquiryResolved,
    TResult Function(SdkEvent_TurnCompleted value)? turnCompleted,
    TResult Function(SdkEvent_ChainCompleted value)? chainCompleted,
    required TResult orElse(),
  }) {
    if (chainCompleted != null) {
      return chainCompleted(this);
    }
    return orElse();
  }
}

abstract class SdkEvent_ChainCompleted extends SdkEvent {
  const factory SdkEvent_ChainCompleted(
      {required final String workspaceId,
      required final String requestId}) = _$SdkEvent_ChainCompletedImpl;
  const SdkEvent_ChainCompleted._() : super._();

  @override
  String get workspaceId;
  String get requestId;

  /// Create a copy of SdkEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdkEvent_ChainCompletedImplCopyWith<_$SdkEvent_ChainCompletedImpl>
      get copyWith => throw _privateConstructorUsedError;
}
