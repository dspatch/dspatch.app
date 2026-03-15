// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Credentials held separately from routing state.
///
/// The router never reads this — it only reads AuthPhase.
/// Read by: BackendAuth (HTTP headers), EngineAuth (/auth/connect),
/// SecureTokenStore (persistence), and the proactive refresh timer.
sealed class AuthToken {
  final String token;
  final int expiresAt;

  const AuthToken({required this.token, required this.expiresAt});
}

/// JWT issued by the d:spatch backend after full authentication.
class BackendToken extends AuthToken {
  /// Only relevant during registration sub-steps.
  final String scope;
  final String username;
  final String email;

  const BackendToken({
    required super.token,
    required super.expiresAt,
    required this.scope,
    required this.username,
    required this.email,
  });
}

/// Token issued by the engine via /auth/anonymous.
class AnonymousToken extends AuthToken {
  const AnonymousToken({
    required super.token,
    required super.expiresAt,
  });
}
