// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';
import 'dart:io';

import 'package:dspatch_engine/dspatch_engine.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// Event fired when a file in the watched directory changes.
enum FileChangeType { added, modified, removed }

class FileChangeEvent {
  final String path;
  final FileChangeType type;

  const FileChangeEvent({required this.path, required this.type});
}

/// Reads the host filesystem directly via [dart:io].
///
/// All paths are resolved relative to [rootPath] (the workspace project dir).
class LocalFileBrowserService {
  LocalFileBrowserService({required this.rootPath});

  /// The workspace project directory (absolute path).
  final String rootPath;

  StreamController<FileChangeEvent>? _watchController;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  Future<List<FileEntry>> listDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return [];

    final entities = <FileSystemEntity>[];
    await for (final entity in dir.list()) {
      if (!p.basename(entity.path).startsWith('.')) {
        entities.add(entity);
      }
    }

    final stats = await Future.wait(
      entities.map((e) => e.stat()),
    );

    final entries = <FileEntry>[];
    for (var i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final stat = stats[i];
      final isDir = stat.type == FileSystemEntityType.directory;
      entries.add(FileEntry(
        name: p.basename(entity.path),
        path: entity.path,
        relativePath:
            p.relative(entity.path, from: rootPath).replaceAll('\\', '/'),
        isDirectory: isDir,
        size: BigInt.from(isDir ? 0 : stat.size),
        modified: stat.modified,
      ));
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  Future<String> readFile(String filePath) {
    return File(filePath).readAsString();
  }

  Future<void> writeFile(String filePath, String content) {
    return File(filePath).writeAsString(content);
  }

  Stream<FileChangeEvent> watchDirectory(String directoryPath) {
    _watcherSubscription?.cancel();
    _watchController?.close();

    final controller = StreamController<FileChangeEvent>.broadcast();
    _watchController = controller;

    final watcher = DirectoryWatcher(directoryPath);
    _watcherSubscription = watcher.events.listen(
      (event) {
        final FileChangeType type;
        if (event.type == ChangeType.ADD) {
          type = FileChangeType.added;
        } else if (event.type == ChangeType.MODIFY) {
          type = FileChangeType.modified;
        } else {
          type = FileChangeType.removed;
        }
        controller.add(FileChangeEvent(path: event.path, type: type));
      },
      onError: controller.addError,
    );

    return controller.stream;
  }

  void dispose() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _watchController?.close();
    _watchController = null;
  }
}
