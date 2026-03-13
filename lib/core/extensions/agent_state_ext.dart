// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Agent state string constants matching the engine's state values.
abstract final class AgentState {
  static const disconnected = 'disconnected';
  static const idle = 'idle';
  static const generating = 'generating';
  static const waitingForInquiry = 'waiting_for_inquiry';
  static const waitingForAgent = 'waiting_for_agent';
  static const completed = 'completed';
  static const failed = 'failed';
  static const crashed = 'crashed';
}

/// Convenience getters on agent status strings for UI display logic.
extension AgentStatusExt on String {
  /// Whether this state is terminal (completed, failed).
  bool get isTerminal =>
      this == AgentState.completed || this == AgentState.failed;

  /// Whether this state is a waiting state (waiting for agent or inquiry).
  bool get isWaiting =>
      this == AgentState.waitingForAgent ||
      this == AgentState.waitingForInquiry;

  /// Whether the agent is actively doing work.
  bool get isActive => this == AgentState.generating || isWaiting;
}
