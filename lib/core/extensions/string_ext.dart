// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
/// Convenience extensions on [String].
extension StringExt on String {
  /// Truncates to [maxLength] characters, appending '...' if truncated.
  String truncated(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Capitalizes the first character, leaving the rest unchanged.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns `true` if this string is a well-formed URL with scheme and host.
  bool isValidUrl() {
    final uri = Uri.tryParse(this);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Returns the first 12 characters, following Docker's short-ID convention.
  String get shortId => length > 12 ? substring(0, 12) : this;

  /// Returns the first 8 characters for log-friendly session/entity IDs.
  String get shortIdForLog => length > 8 ? substring(0, 8) : this;

  /// Returns [fallback] if the string is empty, otherwise returns `this`.
  /// Useful for converting empty form fields to null:
  /// ```dart
  /// textController.text.trim().ifEmpty(null) // null when blank
  /// ```
  String? ifEmpty(String? fallback) => isEmpty ? fallback : this;
}
