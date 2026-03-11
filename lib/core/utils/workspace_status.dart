// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Derived workspace status based on its latest run.
///
/// This is a UI-only concept computed from the workspace run's status string.
/// Not part of the Rust SDK domain model.
enum WorkspaceStatus {
  idle,
  starting,
  running,
  stopping,
  failed;

  bool get isTerminal => this == failed;
  bool get isActive => this == starting || this == running || this == stopping;

  /// Parses a run status string into a [WorkspaceStatus].
  /// Returns [idle] if the string doesn't match any known status.
  static WorkspaceStatus fromRunStatus(String? status) {
    return switch (status) {
      'starting' => WorkspaceStatus.starting,
      'running' => WorkspaceStatus.running,
      'stopping' => WorkspaceStatus.stopping,
      'failed' => WorkspaceStatus.failed,
      _ => WorkspaceStatus.idle,
    };
  }
}
