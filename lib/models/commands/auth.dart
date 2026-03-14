// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for authentication.
///
/// Note: These commands exist in the current Dart engine_client.dart and are
/// sent over WebSocket, but are NOT yet in the Rust Command enum (commands.rs).
/// HTTP endpoints (/auth/*) handle bootstrap auth; these WS commands handle
/// in-session auth. They will be added to the Rust side when auth is fully wired.
library;

import 'command.dart';

class Login extends VoidEngineCommand {
  Login({required this.username, required this.password});
  final String username;
  final String password;

  @override
  String get method => 'login';

  @override
  Map<String, dynamic> get params => {
        'username': username,
        'password': password,
      };
}

class Register extends VoidEngineCommand {
  Register({
    required this.username,
    required this.email,
    required this.password,
  });
  final String username;
  final String email;
  final String password;

  @override
  String get method => 'register';

  @override
  Map<String, dynamic> get params => {
        'username': username,
        'email': email,
        'password': password,
      };
}

class Logout extends VoidEngineCommand {
  @override
  String get method => 'logout';

  @override
  Map<String, dynamic>? get params => null;
}

class EnterAnonymousMode extends VoidEngineCommand {
  @override
  String get method => 'enter_anonymous_mode';

  @override
  Map<String, dynamic>? get params => null;
}

class VerifyEmail extends VoidEngineCommand {
  VerifyEmail({required this.code});
  final String code;

  @override
  String get method => 'verify_email';

  @override
  Map<String, dynamic> get params => {'code': code};
}

class ResendVerification extends VoidEngineCommand {
  @override
  String get method => 'resend_verification';

  @override
  Map<String, dynamic>? get params => null;
}

class Setup2Fa extends VoidEngineCommand {
  @override
  String get method => 'setup_2fa';

  @override
  Map<String, dynamic>? get params => null;
}

class Confirm2Fa extends VoidEngineCommand {
  Confirm2Fa({required this.code});
  final String code;

  @override
  String get method => 'confirm_2fa';

  @override
  Map<String, dynamic> get params => {'code': code};
}

class Verify2Fa extends VoidEngineCommand {
  Verify2Fa({required this.code, this.isBackupCode = false});
  final String code;
  final bool isBackupCode;

  @override
  String get method => 'verify_2fa';

  @override
  Map<String, dynamic> get params => {
        'code': code,
        'is_backup_code': isBackupCode,
      };
}

class AcknowledgeBackupCodes extends VoidEngineCommand {
  @override
  String get method => 'acknowledge_backup_codes';

  @override
  Map<String, dynamic>? get params => null;
}

class RegisterDevice extends VoidEngineCommand {
  RegisterDevice({required this.request});
  final Map<String, dynamic> request;

  @override
  String get method => 'register_device';

  @override
  Map<String, dynamic> get params => request;
}
