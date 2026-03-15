// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Single source of truth for routing decisions.
///
/// AuthController is the only writer. The router maps each phase
/// to exactly one route — no priority cascade, no reconciliation.
enum AuthPhase {
  /// No token, no session.
  unauthenticated,

  /// Registration sub-steps (have partial backend token).
  verifyEmail,
  setup2fa,
  verify2fa,

  /// App-local phase (not a backend scope) — inserted between 2FA
  /// confirm and device registration to force backup code acknowledgement.
  backupCodes,

  deviceRegistration,

  /// Have a valid full token (backend or anonymous), no engine session yet.
  authenticated,

  /// /auth/connect called, WS handshake in progress or established,
  /// waiting for DB state.
  connecting,

  /// Engine signaled migration_pending, waiting for user decision.
  migrating,

  /// Engine WS connected, DB ready, Drift opened.
  ready,
}
