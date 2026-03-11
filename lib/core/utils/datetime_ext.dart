// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
/// Convenience extensions on [DateTime] for display formatting.
extension DateTimeExt on DateTime {
  /// Returns a human-readable relative time string (e.g. '5m ago', '3d ago').
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  /// Formats as `YYYY-MM-DD HH:MM` in local time.
  String formatted() {
    final y = year.toString();
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  /// Returns the UTC ISO 8601 representation (e.g. '2024-01-15T09:30:00.000Z').
  String isoString() => toUtc().toIso8601String();
}
