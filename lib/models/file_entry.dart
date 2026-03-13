// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// A file or directory entry from the local filesystem.
class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.relativePath,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  final String name;
  final String path;
  final String relativePath;
  final bool isDirectory;
  final BigInt size;
  final DateTime modified;
}
