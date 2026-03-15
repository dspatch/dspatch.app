// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Engine database state, written by the WS event listener.
///
/// Uses StateProvider (not stream) so the latest value is always
/// available even if the event arrived before any screen subscribed.
enum DbState {
  unknown,
  migrationPending,
  ready;

  /// Parses engine wire format strings to DbState.
  /// Centralizes the mapping so callers don't duplicate switch logic.
  factory DbState.fromString(String? value) => switch (value) {
        'ready' => DbState.ready,
        'migration_pending' => DbState.migrationPending,
        _ => DbState.unknown,
      };
}
