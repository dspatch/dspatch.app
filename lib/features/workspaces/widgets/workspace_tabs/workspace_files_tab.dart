// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/local_file_browser_service.dart';
import '../../../../models/file_entry.dart';


/// The container mount point for the workspace directory.
const _containerWorkspacePath = '/workspace';

/// File browser tab for the workspace view.
///
/// Displays a flat list with expand/collapse for directories,
/// columns for name/modified/size, and a full-view file opener
/// on double-click.
class WorkspaceFilesTab extends StatefulWidget {
  const WorkspaceFilesTab({
    super.key,
    required this.projectPath,
  });

  final String projectPath;

  @override
  State<WorkspaceFilesTab> createState() => _WorkspaceFilesTabState();
}

class _WorkspaceFilesTabState extends State<WorkspaceFilesTab> {
  late final LocalFileBrowserService _service;

  /// Cache of directory path → children entries.
  final Map<String, List<FileEntry>> _dirCache = {};

  /// Which directory paths are currently expanded.
  final Set<String> _expandedPaths = {};

  /// Computed flat list for the ListView.
  List<_FlatEntry> _flatList = [];

  /// The directory currently being browsed (host path).
  /// Defaults to project root. Changes on double-click into a folder.
  late String _currentDir;

  /// File currently being viewed (null = browser mode).
  FileEntry? _openedFile;
  String? _openedFileContent;
  bool _loadingContent = false;
  bool _isBinaryOrTooLarge = false;

  /// Auto-save debouncer (1s after last edit).
  final _saveDebouncer = Debouncer(duration: const Duration(seconds: 1));
  bool _saving = false;
  DateTime? _lastSavedAt;
  Timer? _savedIndicatorTimer;

  bool _loading = true;

  StreamSubscription<FileChangeEvent>? _watcherSub;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentDir = widget.projectPath;
    _service = LocalFileBrowserService(rootPath: widget.projectPath);
    _loadRoot();
    _startWatching();
  }

  @override
  void didUpdateWidget(covariant WorkspaceFilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectPath != widget.projectPath) {
      _watcherSub?.cancel();
      _debounceTimer?.cancel();
      _service.dispose();

      _dirCache.clear();
      _expandedPaths.clear();
      _openedFile = null;
      _openedFileContent = null;
      _loading = true;
      _currentDir = widget.projectPath;

      _service = LocalFileBrowserService(rootPath: widget.projectPath);
      _loadRoot();
      _startWatching();
    }
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    _savedIndicatorTimer?.cancel();
    _watcherSub?.cancel();
    _debounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  // ── Data loading ──

  Future<void> _loadRoot() async {
    final entries = await _service.listDirectory(_currentDir);
    if (!mounted) return;
    _dirCache[_currentDir] = entries;
    setState(() {
      _loading = false;
      _rebuildFlatList();
    });
  }

  void _startWatching() {
    _watcherSub =
        _service.watchDirectory(widget.projectPath).listen((event) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _refreshChangedDirectory(event.path);
      });
    });
  }

  Future<void> _refreshChangedDirectory(String changedPath) async {
    // Only refresh cached directories that contain the changed path.
    final parentDir = p.dirname(changedPath);
    final dirsToRefresh = _dirCache.keys
        .where((dir) => dir == parentDir || changedPath.startsWith(dir))
        .toList();

    if (dirsToRefresh.isEmpty) return;

    // Refresh in parallel.
    final results = await Future.wait(
      dirsToRefresh.map((dir) => _service.listDirectory(dir)),
    );
    if (!mounted) return;

    for (var i = 0; i < dirsToRefresh.length; i++) {
      _dirCache[dirsToRefresh[i]] = results[i];
    }

    setState(_rebuildFlatList);
  }

  // ── Expand / collapse ──

  Future<void> _toggleDirectory(FileEntry entry) async {
    // Find this entry's index in the flat list.
    final index = _flatList.indexWhere((f) => f.entry.path == entry.path);
    if (index == -1) return;

    if (_expandedPaths.contains(entry.path)) {
      // Collapse: remove descendant rows from flat list.
      _expandedPaths.remove(entry.path);
      _removeChildExpansions(entry.path);

      final parentDepth = _flatList[index].depth;
      var end = index + 1;
      while (end < _flatList.length && _flatList[end].depth > parentDepth) {
        end++;
      }
      setState(() {
        _flatList.removeRange(index + 1, end);
      });
    } else {
      // Expand: load children if not cached, then insert.
      if (!_dirCache.containsKey(entry.path)) {
        final children = await _service.listDirectory(entry.path);
        if (!mounted) return;
        _dirCache[entry.path] = children;
      }
      _expandedPaths.add(entry.path);

      final depth = _flatList[index].depth + 1;
      final children = _dirCache[entry.path] ?? [];
      final newEntries = _buildSubtree(children, depth);
      setState(() {
        _flatList.insertAll(index + 1, newEntries);
      });
    }
  }

  /// Build flat entries for a subtree (including already-expanded children).
  List<_FlatEntry> _buildSubtree(List<FileEntry> entries, int depth) {
    final result = <_FlatEntry>[];
    for (final entry in entries) {
      result.add(_FlatEntry(entry: entry, depth: depth));
      if (entry.isDirectory && _expandedPaths.contains(entry.path)) {
        final children = _dirCache[entry.path] ?? [];
        result.addAll(_buildSubtree(children, depth + 1));
      }
    }
    return result;
  }

  /// Remove expansion state for all children of a collapsed directory.
  void _removeChildExpansions(String parentPath) {
    _expandedPaths.removeWhere(
      (path) => path != parentPath && path.startsWith(parentPath),
    );
  }

  // ── Flat list computation (full rebuild, used only for initial load / watcher) ──

  void _rebuildFlatList() {
    final rootEntries = _dirCache[_currentDir] ?? [];
    _flatList = _buildSubtree(rootEntries, 0);
  }

  // ── Directory navigation ──

  Future<void> _navigateToDirectory(String dirPath) async {
    _expandedPaths.clear();
    _currentDir = dirPath;

    if (_dirCache.containsKey(dirPath)) {
      setState(_rebuildFlatList);
    } else {
      setState(() => _loading = true);
      final entries = await _service.listDirectory(dirPath);
      if (!mounted) return;
      _dirCache[dirPath] = entries;
      setState(() {
        _loading = false;
        _rebuildFlatList();
      });
    }
  }

  // ── File opening ──

  Future<void> _openFile(FileEntry entry) async {
    if (entry.isDirectory) return;

    _saveDebouncer.dispose();
    _savedIndicatorTimer?.cancel();
    setState(() {
      _openedFile = entry;
      _loadingContent = true;
      _isBinaryOrTooLarge = false;
      _saving = false;
      _lastSavedAt = null;
    });

    // Binary guard
    final ext = p.extension(entry.name).toLowerCase();
    if (_binaryExtensions.contains(ext)) {
      setState(() {
        _openedFileContent = 'Binary file — cannot preview.';
        _loadingContent = false;
        _isBinaryOrTooLarge = true;
      });
      return;
    }

    // Size guard (1 MB)
    if (entry.size.toInt() > 1024 * 1024) {
      setState(() {
        _openedFileContent =
            'File too large to preview (${_formatSize(entry.size.toInt())}).';
        _loadingContent = false;
        _isBinaryOrTooLarge = true;
      });
      return;
    }

    try {
      final content = await _service.readFile(entry.path);
      if (!mounted) return;
      setState(() {
        _openedFileContent = content;
        _loadingContent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _openedFileContent = 'Error reading file: $e';
        _loadingContent = false;
        _isBinaryOrTooLarge = true;
      });
    }
  }

  void _closeFile() {
    _saveDebouncer.dispose();
    _savedIndicatorTimer?.cancel();
    setState(() {
      _openedFile = null;
      _openedFileContent = null;
      _isBinaryOrTooLarge = false;
      _saving = false;
      _lastSavedAt = null;
    });
  }

  void _onFileEdited(String content) {
    _saveDebouncer.run(() => _saveFile(content));
  }

  Future<void> _saveFile(String content) async {
    final file = _openedFile;
    if (file == null) return;
    setState(() => _saving = true);
    try {
      await _service.writeFile(file.path, content);
      if (!mounted) return;
      setState(() => _lastSavedAt = DateTime.now());
      _startSavedIndicatorTimer();
    } catch (e) {
      if (mounted) {
        toast('Failed to save: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Ticks every 5s to update the "saved X s ago" label, then clears after 30s.
  void _startSavedIndicatorTimer() {
    _savedIndicatorTimer?.cancel();
    _savedIndicatorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted || _lastSavedAt == null) {
          _savedIndicatorTimer?.cancel();
          return;
        }
        final elapsed = DateTime.now().difference(_lastSavedAt!);
        if (elapsed.inSeconds >= 30) {
          _savedIndicatorTimer?.cancel();
          setState(() => _lastSavedAt = null);
        } else {
          setState(() {}); // Refresh the label.
        }
      },
    );
  }

  // ── Container path helpers ──

  /// Converts a host-relative path to the container path.
  String _containerPath(String relativePath) {
    if (relativePath.isEmpty || relativePath == '.') {
      return _containerWorkspacePath;
    }
    return '$_containerWorkspacePath/$relativePath';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Spinner());
    }

    // File viewer mode
    if (_openedFile != null) {
      return _buildFileViewer();
    }

    // Browser mode
    return _buildBrowser();
  }

  Widget _buildBrowser() {
    if (_flatList.isEmpty) {
      return const ContentArea(
        alignment: Alignment.topLeft,
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: LucideIcons.folder_open,
          title: 'No Files',
          description: 'This workspace directory is empty.',
        ),
      );
    }

    return ContentArea(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Breadcrumb
          _BreadcrumbBar(
            rootPath: widget.projectPath,
            currentDir: _currentDir,
            onNavigate: _navigateToDirectory,
          ),

          // Column headers
          _buildColumnHeaders(),

          // File list
          Expanded(
            child: ListView.builder(
              itemCount: _flatList.length,
              itemExtent: 30,
              itemBuilder: (context, index) {
                final flat = _flatList[index];
                return _FileRow(
                  entry: flat.entry,
                  depth: flat.depth,
                  isExpanded: _expandedPaths.contains(flat.entry.path),
                  onTap: () {
                    if (flat.entry.isDirectory) {
                      _toggleDirectory(flat.entry);
                    }
                  },
                  onDoubleTap: () {
                    if (flat.entry.isDirectory) {
                      _navigateToDirectory(flat.entry.path);
                    } else {
                      _openFile(flat.entry);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
                fontFamily: AppFonts.mono,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Last Modified',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
                fontFamily: AppFonts.mono,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Size',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
                fontFamily: AppFonts.mono,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer() {
    final file = _openedFile!;
    final relPath = _containerPath(file.relativePath);
    final editable = !_isBinaryOrTooLarge;

    return ContentArea(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero,
      child: Column(
      children: [
        // Header with back button and file path
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Button(
                icon: LucideIcons.arrow_left,
                label: 'Back',
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                onPressed: _closeFile,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  relPath,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: AppFonts.mono,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Save indicator
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(right: Spacing.sm),
                  child: Spinner(size: SpinnerSize.sm),
                )
              else if (_lastSavedAt != null)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.sm),
                  child: Text(
                    'saved ${DateTime.now().difference(_lastSavedAt!).inSeconds}s ago',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: AppFonts.mono,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              const SizedBox(width: Spacing.sm),
              Text(
                _formatSize(file.size.toInt()),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: AppFonts.mono,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),

        // File content
        Expanded(
          child: _loadingContent
              ? const Center(child: Spinner())
              : DspatchCodeEditor(
                  content: _openedFileContent ?? '',
                  filename: _openedFile?.name,
                  readOnly: !editable,
                  onChanged: editable ? _onFileEdited : null,
                ),
        ),
      ],
      ),
    );
  }

  static const _binaryExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.webp', '.svg',
    '.mp3', '.mp4', '.wav', '.avi', '.mov', '.mkv',
    '.zip', '.tar', '.gz', '.bz2', '.7z', '.rar',
    '.exe', '.dll', '.so', '.dylib', '.wasm',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx',
    '.pyc', '.class', '.o', '.obj',
  };
}

// ── Flat entry model ──

class _FlatEntry {
  const _FlatEntry({required this.entry, required this.depth});
  final FileEntry entry;
  final int depth;
}

// ── Breadcrumb bar ──

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.rootPath,
    required this.currentDir,
    required this.onNavigate,
  });

  final String rootPath;
  final String currentDir;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    // Build container-relative path segments.
    // /workspace is always the first segment (the root).
    final relativePart =
        p.relative(currentDir, from: rootPath).replaceAll('\\', '/');
    final subSegments = relativePart == '.'
        ? <String>[]
        : relativePart.split('/').where((s) => s.isNotEmpty).toList();

    // All segments: ['workspace', ...subfolders]
    final segments = ['workspace', ...subSegments];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.folder, size: 14, color: AppColors.mutedForeground),
          const SizedBox(width: Spacing.xs),
          const Text(
            '/',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppFonts.mono,
              color: AppColors.mutedForeground,
            ),
          ),
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppFonts.mono,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            if (i == segments.length - 1)
              // Last segment — not clickable
              Text(
                segments[i],
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: AppFonts.mono,
                  color: AppColors.foreground,
                ),
              )
            else
              // Clickable ancestor segment
              GestureDetector(
                onTap: () {
                  // i == 0 → rootPath, i == 1 → rootPath/subSegments[0], etc.
                  if (i == 0) {
                    onNavigate(rootPath);
                  } else {
                    final targetPath = p.joinAll([
                      rootPath,
                      ...subSegments.sublist(0, i),
                    ]);
                    onNavigate(targetPath);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    segments[i],
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: AppFonts.mono,
                      color: AppColors.mutedForeground,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── File row ──

class _FileRow extends StatefulWidget {
  const _FileRow({
    required this.entry,
    required this.depth,
    required this.isExpanded,
    required this.onTap,
    required this.onDoubleTap,
  });

  final FileEntry entry;
  final int depth;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.surfaceHover : null,
          ),
          child: Row(
            children: [
              // Name column (flex 5)
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    // Indentation
                    SizedBox(width: widget.depth * 20.0),
                    // Expand/collapse arrow
                    if (widget.entry.isDirectory)
                      Icon(
                        widget.isExpanded
                            ? LucideIcons.chevron_down
                            : LucideIcons.chevron_right,
                        size: 16,
                        color: AppColors.mutedForeground,
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: Spacing.xs),
                    // Icon
                    Icon(
                      widget.entry.isDirectory
                          ? (widget.isExpanded
                              ? LucideIcons.folder_open
                              : LucideIcons.folder)
                          : _fileIcon(widget.entry.name),
                      size: 16,
                      color: widget.entry.isDirectory
                          ? AppColors.warning
                          : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: Spacing.xs),
                    // Name
                    Expanded(
                      child: Text(
                        widget.entry.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: AppFonts.mono,
                          color: AppColors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Last Modified column (flex 3)
              Expanded(
                flex: 3,
                child: Text(
                  _formatDate(widget.entry.modified),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: AppFonts.mono,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),

              // Size column (80px)
              SizedBox(
                width: 80,
                child: Text(
                  widget.entry.isDirectory
                      ? '—'
                      : _formatSize(widget.entry.size.toInt()),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: AppFonts.mono,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _fileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.py' => LucideIcons.code,
      '.dart' => LucideIcons.code,
      '.js' || '.ts' || '.jsx' || '.tsx' => LucideIcons.code,
      '.json' => LucideIcons.braces,
      '.yaml' || '.yml' => LucideIcons.settings,
      '.md' => LucideIcons.file_text,
      '.txt' => LucideIcons.file_text,
      '.toml' => LucideIcons.settings,
      '.lock' => LucideIcons.lock,
      '.sh' || '.bash' => LucideIcons.terminal,
      _ => LucideIcons.file,
    };
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ── Shared helpers ──

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
