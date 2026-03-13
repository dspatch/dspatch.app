// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Auth state received from the engine via WebSocket events.
class AuthState {
  final String mode;
  final String? tokenScope;
  final String? username;
  final String? email;

  const AuthState({
    required this.mode,
    this.tokenScope,
    this.username,
    this.email,
  });

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      mode: json['mode'] as String,
      tokenScope: json['token_scope'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Auth mode constants matching the engine's enum values.
class AuthMode {
  static const undetermined = 'undetermined';
  static const anonymous = 'anonymous';
  static const connected = 'connected';
}

/// Token scope constants matching the engine's enum values.
class TokenScope {
  static const full = 'full';
  static const emailVerification = 'email_verification';
  static const partial2Fa = 'partial_2fa';
  static const setup2Fa = 'setup_2fa';
  static const awaitingBackupConfirmation = 'awaiting_backup_confirmation';
  static const deviceRegistration = 'device_registration';
}
