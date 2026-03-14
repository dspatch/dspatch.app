// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed response models for config, crypto, and other engine commands.
library;

import 'commands/command.dart';
import 'workspace_config.dart';

class ParseWorkspaceConfigResponse extends EngineResponse {
  const ParseWorkspaceConfigResponse({required this.config});

  final WorkspaceConfig config;

  factory ParseWorkspaceConfigResponse.fromJson(Map<String, dynamic> json) {
    return ParseWorkspaceConfigResponse(
      config: WorkspaceConfig.fromJson(json),
    );
  }
}

class ValidationResult extends EngineResponse {
  const ValidationResult({required this.valid, required this.errors});

  final bool valid;
  final List<String> errors;

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] as bool? ?? false,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class EncryptionResult extends EngineResponse {
  const EncryptionResult({required this.ciphertext});

  final String ciphertext;

  factory EncryptionResult.fromJson(Map<String, dynamic> json) {
    return EncryptionResult(
      ciphertext: json['ciphertext'] as String? ?? '',
    );
  }
}

class DecryptionResult extends EngineResponse {
  const DecryptionResult({required this.plaintext});

  final String plaintext;

  factory DecryptionResult.fromJson(Map<String, dynamic> json) {
    return DecryptionResult(
      plaintext: json['plaintext'] as String? ?? '',
    );
  }
}

class TemplateResolutionResult extends EngineResponse {
  const TemplateResolutionResult({required this.raw});

  /// Raw JSON from the engine. Fields TBD from Rust struct inspection.
  final Map<String, dynamic> raw;

  factory TemplateResolutionResult.fromJson(Map<String, dynamic> json) {
    return TemplateResolutionResult(raw: json);
  }
}

class EncodeWorkspaceYamlResponse extends EngineResponse {
  const EncodeWorkspaceYamlResponse({required this.yaml});

  final String yaml;

  factory EncodeWorkspaceYamlResponse.fromJson(Map<String, dynamic> json) {
    return EncodeWorkspaceYamlResponse(
      yaml: json['yaml'] as String? ?? '',
    );
  }
}

class DatabaseStateResponse extends EngineResponse {
  const DatabaseStateResponse({required this.raw});

  final Map<String, dynamic> raw;

  factory DatabaseStateResponse.fromJson(Map<String, dynamic> json) {
    return DatabaseStateResponse(raw: json);
  }
}
