// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';


/// Pure validation utility for the agent provider form.
///
/// Each method returns `null` if valid, or an error message string if invalid.
/// Used with [Field]'s `error` prop for inline validation.
class AgentProviderFormValidator {
  AgentProviderFormValidator._();

  /// Validates template name: required, 1-64 characters.
  static String? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Template name is required';
    if (trimmed.length > 64) return 'Name must be 64 characters or less';
    return null;
  }

  /// Validates entry point: required, non-empty.
  static String? validateEntryPoint(String value) {
    if (value.trim().isEmpty) return 'Entry point is required';
    return null;
  }

  /// Validates source path: required, must exist, must be a git repository.
  static String? validateSourcePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Source path is required';
    if (!Directory(trimmed).existsSync()) return 'Directory does not exist';
    if (!Directory('$trimmed/.git').existsSync()) {
      return 'Directory must be a git repository';
    }
    return null;
  }

  /// Validates git URL: required for git source type.
  /// Accepts HTTPS URLs and SSH-style URLs (git@host:org/repo.git).
  static String? validateGitUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Repository URL is required';
    final isHttps = Uri.tryParse(trimmed)?.hasScheme ?? false;
    final isSsh = RegExp(r'^[\w.-]+@[\w.-]+:').hasMatch(trimmed);
    if (!isHttps && !isSsh) return 'Invalid git URL format';
    return null;
  }

  /// Validates a single required env key: non-empty, valid identifier format.
  static String? validateRequiredEnvKey(String key) {
    if (key.trim().isEmpty) return 'Key cannot be empty';
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key.trim())) {
      return 'Invalid key format (use letters, digits, underscores)';
    }
    return null;
  }

  /// Validates all fields and returns a map of fieldName → error message.
  /// Returns empty map if all valid.
  static Map<String, String?> validateAll({
    required String name,
    required String entryPoint,
    required String sourceType,
    required String sourcePath,
    required String gitUrl,
    required List<String> requiredEnv,
  }) {
    final errors = <String, String?>{};
    errors['name'] = validateName(name);
    errors['entryPoint'] = validateEntryPoint(entryPoint);

    if (sourceType == 'local') {
      errors['sourcePath'] = validateSourcePath(sourcePath);
    }
    if (sourceType == 'git') {
      errors['gitUrl'] = validateGitUrl(gitUrl);
    }

    // Validate each required env key.
    for (var i = 0; i < requiredEnv.length; i++) {
      final keyError = validateRequiredEnvKey(requiredEnv[i]);
      if (keyError != null) {
        errors['requiredEnv_$i'] = keyError;
      }
    }

    // Check for duplicate keys.
    final seen = <String>{};
    for (var i = 0; i < requiredEnv.length; i++) {
      final key = requiredEnv[i].trim();
      if (key.isNotEmpty && !seen.add(key)) {
        errors['requiredEnv_$i'] = 'Duplicate key "$key"';
      }
    }

    // Remove null entries (valid fields).
    errors.removeWhere((_, v) => v == null);
    return errors;
  }
}
