// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

class BackendAuthState {
  final String token;
  final int expiresAt;
  final String scope;
  final String username;
  final String email;

  const BackendAuthState({
    required this.token,
    required this.expiresAt,
    required this.scope,
    required this.username,
    required this.email,
  });

  bool get isFullyAuthenticated => scope == 'full';
}
