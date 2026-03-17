// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:path/path.dart' as p;

/// Scans agent source directories and reads configuration from
/// `dspatch.agent.yml` (entry point, required env keys, mounts, readme).
class AgentSourceScanner {
  AgentSourceScanner._();

  static File? _findAgentYaml(String directory) {
    for (final name in ['dspatch.agent.yml']) {
      final candidate = File('$directory/$name');
      if (candidate.existsSync()) return candidate;
    }
    return null;
  }

  /// Scans Python files in [directory] for the DspatchEngine pattern.
  ///
  /// Looks for files that instantiate `DspatchEngine()` and use the
  /// `@<var>.agent` decorator. Returns the filename (not full path)
  /// of the first matching file, or `null` if none found.
  ///
  /// Only scans `.py` files at the root level (not recursive).
  static Future<String?> detectEntryPoint(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return null;

    final pyFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.py'))
        .toList();

    final instantiationPattern = RegExp(r'(\w+)\s*=\s*DspatchEngine\(\)');
    for (final file in pyFiles) {
      try {
        final content = await file.readAsString();
        if (!content.contains('DspatchEngine()')) continue;

        final match = instantiationPattern.firstMatch(content);
        if (match != null) {
          final varName = match.group(1)!;
          // Check for @<var>.agent decorator usage.
          if (content.contains('@$varName.agent')) {
            return p.basename(file.path);
          }
        }
      } catch (_) {
        // Skip files that can't be read (encoding issues, etc.).
      }
    }
    return null;
  }

  /// Reads required mounts from `dspatch.agent.yml` in [directory].
  static Future<List<String>> readRequiredMounts(String directory) async {
    final file = _findAgentYaml(directory);
    if (file == null) return [];

    try {
      final lines = await file.readAsLines();
      final mounts = <String>[];
      var inMountsBlock = false;

      for (final line in lines) {
        if (mounts.length >= 50) break;

        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          if (inMountsBlock && trimmed.isEmpty) continue;
          if (trimmed.startsWith('#')) continue;
          continue;
        }

        if (trimmed == 'required_mounts:') {
          inMountsBlock = true;
          continue;
        }

        if (inMountsBlock) {
          if (trimmed.startsWith('- ')) {
            final value = trimmed.substring(2).trim();
            if (value.isNotEmpty) {
              mounts.add(value);
            }
          } else {
            break;
          }
        }
      }
      return mounts;
    } catch (_) {
      return [];
    }
  }

  /// Reads required env key names from `dspatch.agent.yml` in [directory].
  static Future<List<String>> readRequiredEnv(String directory) async {
    final file = _findAgentYaml(directory);
    if (file == null) return [];
    try {
      final lines = await file.readAsLines();
      final keys = <String>[];
      var inBlock = false;
      for (final line in lines) {
        if (keys.length >= 50) break;
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          if (inBlock && trimmed.isEmpty) continue;
          continue;
        }
        if (trimmed == 'required_env:') {
          inBlock = true;
          continue;
        }
        if (inBlock) {
          if (trimmed.startsWith('- ')) {
            final value = trimmed.substring(2).trim();
            if (value.isNotEmpty) keys.add(value);
          } else {
            break;
          }
        }
      }
      return keys;
    } catch (_) {
      return [];
    }
  }

  /// Reads the `entry_point` field from `dspatch.agent.yml` in [directory].
  static Future<String?> readEntryPoint(String directory) =>
      _readYmlField(directory, 'entry_point');

  /// Reads the `readme` field from `dspatch.agent.yml` in [directory].
  /// Falls back to auto-detecting README.md or readme.md if the field is absent.
  static Future<String?> readReadme(String directory) async {
    final declared = await _readYmlField(directory, 'readme');
    if (declared != null) return declared;
    for (final name in ['README.md', 'readme.md', 'README.rst', 'README.txt']) {
      if (File('$directory/$name').existsSync()) return name;
    }
    return null;
  }

  static Future<String?> _readYmlField(String directory, String key) async {
    final file = _findAgentYaml(directory);
    if (file == null) return null;
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.startsWith(' ') || line.startsWith('\t')) continue;
        final trimmed = line.trim();
        if (trimmed == '$key:' || trimmed.startsWith('$key: ')) {
          var value = trimmed.substring(key.length + 1).trim();
          if ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'"))) {
            value = value.substring(1, value.length - 1);
          }
          return value.isNotEmpty ? value : null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reads the `name` field from `dspatch.agent.yml` in [directory].
  static Future<String?> readName(String directory) =>
      _readYmlField(directory, 'name');

  /// Reads the `description` field from `dspatch.agent.yml` in [directory].
  static Future<String?> readDescription(String directory) =>
      _readYmlField(directory, 'description');

  /// Reads `fields:` map from `dspatch.agent.yml` in [directory].
  static Future<Map<String, String>> readFields(String directory) async {
    final file = _findAgentYaml(directory);
    if (file == null) return {};
    try {
      final lines = await file.readAsLines();
      final fields = <String, String>{};
      var inBlock = false;
      for (final line in lines) {
        if (fields.length >= 50) break;
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          if (inBlock && trimmed.isEmpty) continue;
          continue;
        }
        if (trimmed == 'fields:') {
          inBlock = true;
          continue;
        }
        if (inBlock) {
          if (line.startsWith(' ') || line.startsWith('\t')) {
            final colonIdx = trimmed.indexOf(':');
            if (colonIdx > 0) {
              final key = trimmed.substring(0, colonIdx).trim();
              var value = trimmed.substring(colonIdx + 1).trim();
              if ((value.startsWith('"') && value.endsWith('"')) ||
                  (value.startsWith("'") && value.endsWith("'"))) {
                value = value.substring(1, value.length - 1);
              }
              if (key.isNotEmpty && value.isNotEmpty) {
                fields[key] = value;
              }
            }
          } else {
            break;
          }
        }
      }
      return fields;
    } catch (_) {
      return {};
    }
  }

  /// Extracts a repository name from a git URL.
  static String? extractRepoName(String gitUrl) {
    final trimmed = gitUrl.trim();
    if (trimmed.isEmpty) return null;

    final stripped = trimmed.endsWith('.git')
        ? trimmed.substring(0, trimmed.length - 4)
        : trimmed;
    final lastSlash = stripped.lastIndexOf('/');
    final lastColon = stripped.lastIndexOf(':');
    final sep = lastSlash > lastColon ? lastSlash : lastColon;
    if (sep < 0 || sep == stripped.length - 1) return null;
    return stripped.substring(sep + 1);
  }

}
