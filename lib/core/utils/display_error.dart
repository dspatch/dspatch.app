// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

/// Converts an error object to a user-friendly display string.
///
/// Strips exception wrappers and provides readable messages for
/// common error types.
String displayError(Object error) {
  // Check for engine-unreachable errors (connection refused, timeout, etc.)
  if (isEngineUnreachableError(error)) {
    return 'Engine is not reachable';
  }
  if (error is SocketException) {
    return 'Network error: ${error.message}';
  }
  if (error is HttpException) {
    return 'Server error: ${error.message}';
  }
  if (error is FormatException) {
    return 'Invalid format: ${error.message}';
  }
  if (error is FileSystemException) {
    return 'File system error: ${error.message}';
  }

  // Fall through: just use toString, stripping "Exception: " prefix.
  final s = error.toString();
  if (s.startsWith('Exception: ')) return s.substring(11);
  return s;
}

/// Returns true if the error indicates the engine process is unreachable
/// (connection refused, timeout, etc.).
bool isEngineUnreachableError(Object error) {
  final s = error.toString();
  return s.contains('Connection refused') ||
      s.contains('Netzwerkverbindung abgelehnt') ||
      s.contains('SocketException') ||
      s.contains('TimeoutException') ||
      (s.contains('ClientException') && s.contains('errno'));
}
