// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for session management (credential refresh).
library;

import 'command.dart';

class RefreshCredentials extends VoidEngineCommand {
  final String backendToken;

  RefreshCredentials({required this.backendToken});

  @override
  String get method => 'refresh_credentials';

  @override
  Map<String, dynamic>? get params => {'backend_token': backendToken};
}
