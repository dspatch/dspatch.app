// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for session management (credential refresh).
library;

import 'command.dart';

class RefreshCredentials extends VoidEngineCommand {
  RefreshCredentials({
    required this.backendToken,
    this.deviceId,
    this.identityKeySeed,
  });

  final String backendToken;
  final String? deviceId;
  final String? identityKeySeed;

  @override
  String get method => 'refresh_credentials';

  @override
  Map<String, dynamic> get params => {
        'backend_token': backendToken,
        if (deviceId != null) 'device_id': deviceId,
        if (identityKeySeed != null) 'identity_key_seed': identityKeySeed,
      };
}
