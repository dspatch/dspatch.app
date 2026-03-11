// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Severity level for editor diagnostics.
enum JsonEditorSeverity { error, warning, info }

/// A diagnostic message to display in the editor's error panel.
class JsonEditorError {
  const JsonEditorError({
    required this.message,
    this.line,
    this.severity = JsonEditorSeverity.error,
  });

  final String message;

  /// 1-based line number. Null means a general (non-line-specific) error.
  final int? line;
  final JsonEditorSeverity severity;
}

/// JSON code editor with syntax highlighting, line numbers, and error panel.
///
/// Uses [DspatchCodeEditor] for the editor and adds a diagnostic error panel
/// below it.
class JsonEditor extends StatefulWidget {
  const JsonEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.errors = const [],
    this.readOnly = false,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final List<JsonEditorError> errors;
  final bool readOnly;

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  // Capture once so DspatchCodeEditor's didUpdateWidget doesn't recreate
  // the controller on every parent setState (e.g. after validation).
  late final String _initialContent = widget.initialValue;
  final _editorController = DspatchCodeEditorController();

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DspatchCodeEditor(
            content: _initialContent,
            language: 'yaml',
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            editorController: _editorController,
          ),
        ),
        if (widget.errors.isNotEmpty) _buildErrorPanel(),
      ],
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        itemCount: widget.errors.length,
        itemBuilder: (context, index) {
          final error = widget.errors[index];
          return _ErrorRow(
            error: error,
            onTap: error.line != null
                ? () => _editorController.jumpToLine(error.line!)
                : null,
          );
        },
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error, this.onTap});

  final JsonEditorError error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (error.severity) {
      JsonEditorSeverity.error => (LucideIcons.circle_alert, AppColors.error),
      JsonEditorSeverity.warning => (LucideIcons.triangle_alert, AppColors.warning),
      JsonEditorSeverity.info => (LucideIcons.info, AppColors.info),
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: Spacing.xs),
            if (error.line != null) ...[
              Text(
                'Ln ${error.line}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppFonts.mono,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(width: Spacing.xs),
            ],
            Expanded(
              child: Text(
                error.message,
                style: TextStyle(fontSize: 12, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
