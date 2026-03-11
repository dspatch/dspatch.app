import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'code_editor_languages.dart';

/// Controller for [DspatchCodeEditor] that exposes navigation commands
/// without leaking the underlying `re_editor` types.
class DspatchCodeEditorController extends ChangeNotifier {
  int _targetLine = -1;

  /// The most recently requested 1-based line number, or -1 if none.
  int get targetLine => _targetLine;

  /// Move the cursor to the beginning of [line] (1-based).
  void jumpToLine(int line) {
    _targetLine = line;
    notifyListeners();
  }
}

/// A syntax-highlighted code editor with line numbers, code folding, and the
/// dspatch dark theme.
///
/// Supports 35+ languages via re_highlight with automatic detection from a
/// [filename] extension. Manages its own [CodeLineEditingController]
/// lifecycle.
///
/// ```dart
/// // Read-only file viewer:
/// DspatchCodeEditor(
///   content: fileContent,
///   filename: 'main.py',
///   readOnly: true,
/// )
///
/// // Editable with save hook:
/// DspatchCodeEditor(
///   content: initialContent,
///   language: 'json',
///   onChanged: (text) => setState(() => _dirty = true),
///   onSave: (text) => saveFile(text),
/// )
/// ```
class DspatchCodeEditor extends StatefulWidget {
  const DspatchCodeEditor({
    super.key,
    required this.content,
    this.filename,
    this.language,
    this.readOnly = false,
    this.onChanged,
    this.onSave,
    this.editorController,
  });

  /// The text content to display.
  final String content;

  /// Filename used for automatic language detection (e.g. `'main.py'`).
  /// Ignored when [language] is provided explicitly.
  final String? filename;

  /// Explicit language key (e.g. `'python'`, `'json'`). Overrides [filename]
  /// detection. Must be a key in [kSupportedLanguageModes] or `null`.
  final String? language;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Called when the editor content changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user presses Ctrl+S (or Cmd+S on macOS).
  /// Receives the current editor content.
  final ValueChanged<String>? onSave;

  /// Optional controller for programmatic navigation (e.g. jump-to-line).
  final DspatchCodeEditorController? editorController;

  @override
  State<DspatchCodeEditor> createState() => _DspatchCodeEditorState();
}

class _DspatchCodeEditorState extends State<DspatchCodeEditor> {
  late CodeLineEditingController _controller;
  bool _ready = false;
  String? _resolvedLanguage;

  @override
  void initState() {
    super.initState();
    _resolvedLanguage = _resolveLanguage();
    _controller = CodeLineEditingController.fromText(
      widget.content,
      const CodeLineOptions(indentSize: 2),
    );
    widget.editorController?.addListener(_onEditorControllerChanged);
    // Defer CodeEditor mount so the platform view is ready for text input.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void didUpdateWidget(covariant DspatchCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editorController != oldWidget.editorController) {
      oldWidget.editorController?.removeListener(_onEditorControllerChanged);
      widget.editorController?.addListener(_onEditorControllerChanged);
    }
    if (widget.content != oldWidget.content) {
      _controller.dispose();
      _controller = CodeLineEditingController.fromText(
        widget.content,
        const CodeLineOptions(indentSize: 2),
      );
      _resolvedLanguage = _resolveLanguage();
    } else if (widget.language != oldWidget.language ||
        widget.filename != oldWidget.filename) {
      setState(() => _resolvedLanguage = _resolveLanguage());
    }
  }

  @override
  void dispose() {
    widget.editorController?.removeListener(_onEditorControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onEditorControllerChanged() {
    final line = widget.editorController?.targetLine ?? -1;
    if (line < 1) return;
    _controller.selection = CodeLineSelection.collapsed(
      index: line - 1,
      offset: 0,
    );
  }

  String? _resolveLanguage() {
    if (widget.language != null) return widget.language;
    if (widget.filename != null) return languageFromFilename(widget.filename!);
    return null;
  }

  CodeHighlightTheme _buildTheme() {
    final languages = <String, CodeHighlightThemeMode>{};
    if (_resolvedLanguage != null) {
      final mode = kSupportedLanguageModes[_resolvedLanguage];
      if (mode != null) {
        languages[_resolvedLanguage!] = CodeHighlightThemeMode(mode: mode);
      }
    }
    return CodeHighlightTheme(
      languages: languages,
      theme: {
        ...atomOneDarkTheme,
        'root': TextStyle(
          color: atomOneDarkTheme['root']?.color ?? AppColors.foreground,
          backgroundColor: AppColors.bgDeep,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(color: AppColors.bgDeep);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: CodeEditor(
        controller: _controller,
        style: CodeEditorStyle(
          fontSize: 13,
          fontFamily: AppFonts.mono,
          fontHeight: 1.5,
          backgroundColor: AppColors.bgDeep,
          textColor: AppColors.foreground,
          cursorColor: AppColors.accent,
          cursorLineColor: AppColors.surfaceHover,
          selectionColor: AppColors.accentGlow,
          hintTextColor: AppColors.mutedForeground,
          codeTheme: _buildTheme(),
        ),
        padding: const EdgeInsets.all(Spacing.sm),
        readOnly: widget.readOnly,
        wordWrap: false,
        indicatorBuilder: _buildIndicator,
        sperator: Container(width: 1, color: AppColors.border),
        shortcutOverrideActions: widget.onSave != null
            ? {
                CodeShortcutSaveIntent: CallbackAction<CodeShortcutSaveIntent>(
                  onInvoke: (_) {
                    widget.onSave?.call(_controller.text);
                    return null;
                  },
                ),
              }
            : null,
        onChanged: widget.onChanged != null
            ? (_) => widget.onChanged!(_controller.text)
            : null,
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    CodeLineEditingController editingController,
    CodeChunkController chunkController,
    CodeIndicatorValueNotifier notifier,
  ) {
    return Row(
      children: [
        DefaultCodeLineNumber(
          controller: editingController,
          notifier: notifier,
          textStyle: const TextStyle(
            fontSize: 13,
            fontFamily: AppFonts.mono,
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
          focusedTextStyle: const TextStyle(
            fontSize: 13,
            fontFamily: AppFonts.mono,
            color: AppColors.foreground,
            height: 1.5,
          ),
          minNumberCount: 3,
        ),
        DefaultCodeChunkIndicator(
          width: 20,
          controller: chunkController,
          notifier: notifier,
        ),
      ],
    );
  }
}
