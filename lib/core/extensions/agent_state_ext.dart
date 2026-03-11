// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';

/// Convenience getters on [AgentState] for UI display logic.
extension AgentStateExt on AgentState {
  /// Whether this state is terminal (completed, failed).
  bool get isTerminal => this == AgentState.completed || this == AgentState.failed;

  /// Whether this state is a waiting state (waiting for agent or inquiry).
  bool get isWaiting =>
      this == AgentState.waitingForAgent || this == AgentState.waitingForInquiry;

  /// Whether the agent is actively doing work.
  bool get isActive => this == AgentState.generating || isWaiting;
}
