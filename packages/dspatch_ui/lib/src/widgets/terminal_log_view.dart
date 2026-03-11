import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'copy_button.dart';

/// A structured log entry with optional level for color coding.
class LogEntry {
  const LogEntry(this.text, {this.level});

  final String text;

  /// Log level: 'debug', 'info', 'warn', 'error'. Null uses default styling.
  final String? level;
}

/// A terminal-style log viewer with automatic syntax highlighting for
/// HTTP request/response patterns.
class TerminalLogView extends StatefulWidget {
  final List<LogEntry> logs;
  final String? error;
  final double maxHeight;

  /// Optional scroll controller for external auto-scrolling.
  final ScrollController? controller;

  /// Pre-built text to copy to clipboard.
  /// When non-null a copy button is shown in the title bar.
  final String? copyText;

  /// Border radius for the outer container. Defaults to [BorderRadius.zero].
  final BorderRadius borderRadius;

  /// When true the widget expands to fill available space (ignores [maxHeight]).
  /// Defaults to true.
  final bool expand;

  const TerminalLogView({
    super.key,
    required this.logs,
    this.error,
    this.maxHeight = 300,
    this.controller,
    this.copyText,
    this.borderRadius = BorderRadius.zero,
    this.expand = true,
  });

  @override
  State<TerminalLogView> createState() => _TerminalLogViewState();
}

class _TerminalLogViewState extends State<TerminalLogView> {
  bool _wrapLines = false;
  final ScrollController _horizontalController = ScrollController();
  ScrollController? _fallbackVerticalController;

  /// Returns the vertical scroll controller — uses the provided one or a
  /// locally-managed fallback so that the explicit [Scrollbar] widgets never
  /// depend on [PrimaryScrollController].
  ScrollController get _verticalController =>
      widget.controller ?? (_fallbackVerticalController ??= ScrollController());

  @override
  void dispose() {
    _horizontalController.dispose();
    _fallbackVerticalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty && widget.error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints:
          widget.expand ? null : BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: widget.borderRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Column(
          mainAxisSize:
              widget.expand ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C28),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.terminal,
                      size: 12, color: AppColors.mutedForeground),
                  const SizedBox(width: 6),
                  const Text(
                    'Output',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedForeground,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.logs.length} lines',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.mutedForeground,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                  if (widget.copyText != null) ...[
                    const SizedBox(width: 8),
                    CopyButton(
                      textToCopy: widget.copyText!,
                      iconSize: 12,
                      copiedColor: AppColors.terminalGreen,
                    ),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _wrapLines = !_wrapLines),
                    child: Icon(
                      LucideIcons.text_wrap,
                      size: 12,
                      color: _wrapLines
                          ? AppColors.terminalBlue
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            // Error banner (if present)
            if (widget.error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: AppColors.destructive.withValues(alpha: 0.1),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'ERROR ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.destructive,
                          fontFamily: AppFonts.mono,
                        ),
                      ),
                      TextSpan(
                        text: widget.error,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.destructive,
                          fontFamily: AppFonts.mono,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Log lines
            if (widget.logs.isNotEmpty)
              Flexible(
                child: _wrapLines ? _buildWrappedLogs() : _buildNoWrapLogs(),
              ),
          ],
        ),
      ),
    );
  }

  static const _logTextStyle = TextStyle(
    fontSize: 11,
    height: 1.6,
    fontFamily: AppFonts.mono,
    color: _defaultColor,
  );

  Widget _buildNoWrapLogs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (notification) => notification.depth == 1,
            child: SingleChildScrollView(
              controller: _verticalController,
              primary: false,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SelectableText.rich(
                      TextSpan(
                        children: _buildHighlightedLines(),
                        style: _logTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWrappedLogs() {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        primary: false,
        padding: const EdgeInsets.all(10),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.logs.length; i++)
                _buildWrappedLine(i),
              if (widget.error != null) _buildWrappedErrorLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedLine(int index) {
    final lineNum = '${(index + 1).toString().padLeft(4)}  ';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lineNum,
          style: const TextStyle(
            fontSize: 11,
            height: 1.6,
            fontFamily: AppFonts.mono,
            color: _lineNumberColor,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: _highlightEntry(widget.logs[index]),
              style: _logTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWrappedErrorLine() {
    final lineNum = '${(widget.logs.length + 1).toString().padLeft(4)}  ';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lineNum,
          style: const TextStyle(
            fontSize: 11,
            height: 1.6,
            fontFamily: AppFonts.mono,
            color: _lineNumberColor,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'ERROR ',
                  style: TextStyle(
                    color: AppColors.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: widget.error,
                  style: const TextStyle(color: AppColors.destructive),
                ),
              ],
              style: _logTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildHighlightedLines() {
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.logs.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      // Line number
      final lineNum = '${(i + 1).toString().padLeft(4)}  ';
      spans.add(TextSpan(
        text: lineNum,
        style: const TextStyle(color: _lineNumberColor),
      ));
      spans.addAll(_highlightEntry(widget.logs[i]));
    }
    // Append error inline at the end of the logs
    if (widget.error != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      final lineNum =
          '${(widget.logs.length + 1).toString().padLeft(4)}  ';
      spans.add(TextSpan(
        text: lineNum,
        style: const TextStyle(color: _lineNumberColor),
      ));
      spans.add(const TextSpan(
        text: 'ERROR ',
        style: TextStyle(
          color: AppColors.destructive,
          fontWeight: FontWeight.w600,
        ),
      ));
      spans.add(TextSpan(
        text: widget.error,
        style: const TextStyle(color: AppColors.destructive),
      ));
    }
    return spans;
  }

  // ── Colors ───────────────────────────────────────────────────────────

  static const _defaultColor = Color(0xFF8A8999);
  static const _lineNumberColor = Color(0xFF45435A);
  static const _methodColor = AppColors.terminalBlue;
  static const _pathColor = Color(0xFF6B9BF7);
  static const _arrowColor = Color(0xFF6B6A7A);
  static const _keyColor = Color(0xFF6B6A7A);
  static const _valueColor = AppColors.foreground;
  static const _fixtureColor = AppColors.terminalAmber;
  static const _dbColor = AppColors.terminalBlue;
  static const _stringColor = AppColors.terminalAmber;
  static const _successColor = Color(0xFF9DCE68);
  static const _progressColor = Color(0xFFDFAF66);

  // ── HTTP method regex ────────────────────────────────────────────────

  static final _httpMethodRe =
      RegExp(r'^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(/\S*)(.*)');
  static final _responseRe = RegExp(r'^(\s*→\s*)(\d{3})(.*)');
  static final _kvRe = RegExp(r'(\w+)=(\S+)');
  static final _successRe = RegExp(
    r'(deleted|stopped|removed|built successfully|cleaned|completed)',
    caseSensitive: false,
  );

  // ── Level colors ─────────────────────────────────────────────────────

  static const _errorColor = AppColors.terminalRose;
  static const _warnColor = AppColors.terminalAmber;
  static const _debugColor = Color(0xFF5E5D6E);

  // ── Per-line highlighting ────────────────────────────────────────────

  /// Highlights a [LogEntry], applying level-based coloring for error/warn/debug.
  /// Info-level lines use the default pattern-based highlighting.
  List<InlineSpan> _highlightEntry(LogEntry entry) {
    final level = entry.level;
    if (level == 'error') {
      return [
        TextSpan(text: entry.text, style: const TextStyle(color: _errorColor))
      ];
    }
    if (level == 'warn') {
      return [
        TextSpan(text: entry.text, style: const TextStyle(color: _warnColor))
      ];
    }
    if (level == 'debug') {
      return [
        TextSpan(text: entry.text, style: const TextStyle(color: _debugColor))
      ];
    }
    if (level == 'received') {
      return [
        TextSpan(
            text: entry.text,
            style: const TextStyle(color: AppColors.terminalGreen))
      ];
    }
    return _highlightLine(entry.text);
  }

  List<InlineSpan> _highlightLine(String line) {
    // HTTP request line: "POST /api/auth/register  user=xxx"
    final httpMatch = _httpMethodRe.firstMatch(line);
    if (httpMatch != null) {
      return _highlightHttpLine(
        httpMatch.group(1)!,
        httpMatch.group(2)!,
        httpMatch.group(3)!,
      );
    }

    // Response line: "  → 201  token=yes"
    final respMatch = _responseRe.firstMatch(line);
    if (respMatch != null) {
      return _highlightResponseLine(
        respMatch.group(1)!,
        respMatch.group(2)!,
        respMatch.group(3)!,
      );
    }

    // Fixture setup: "Fixture: ..."
    if (line.startsWith('Fixture:')) {
      return _highlightPrefixedLine(line, 'Fixture:', _fixtureColor);
    }

    // DB operation: "DB: ..."
    if (line.startsWith('DB:')) {
      return _highlightPrefixedLine(line, 'DB:', _dbColor);
    }

    // Operation console: error lines
    if (line.startsWith('ERROR:')) {
      return _highlightPrefixedLine(line, 'ERROR:', AppColors.destructive);
    }

    // Operation console: success lines (completed operations)
    if (_successRe.hasMatch(line)) {
      return [TextSpan(text: line, style: const TextStyle(color: _successColor))];
    }

    // Operation console: in-progress lines (ending with "...")
    if (line.endsWith('...')) {
      return [TextSpan(text: line, style: const TextStyle(color: _progressColor))];
    }

    // Default: highlight key=value pairs
    return _highlightKeyValues(line);
  }

  List<InlineSpan> _highlightHttpLine(
    String method,
    String path,
    String rest,
  ) {
    return [
      TextSpan(
        text: method,
        style: const TextStyle(
          color: _methodColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      const TextSpan(text: ' '),
      TextSpan(
        text: path,
        style: const TextStyle(color: _pathColor),
      ),
      ..._highlightKeyValues(rest),
    ];
  }

  List<InlineSpan> _highlightResponseLine(
    String arrow,
    String statusCode,
    String rest,
  ) {
    final code = int.tryParse(statusCode) ?? 0;
    final statusColor = switch (code) {
      >= 200 && < 300 => AppColors.terminalGreen,
      >= 300 && < 400 => AppColors.terminalBlue,
      >= 400 && < 500 => AppColors.terminalAmber,
      >= 500 => AppColors.terminalRose,
      _ => _defaultColor,
    };

    return [
      TextSpan(
        text: arrow,
        style: const TextStyle(color: _arrowColor),
      ),
      TextSpan(
        text: statusCode,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      ..._highlightKeyValues(rest),
    ];
  }

  List<InlineSpan> _highlightPrefixedLine(
    String line,
    String prefix,
    Color prefixColor,
  ) {
    return [
      TextSpan(
        text: prefix,
        style: TextStyle(
          color: prefixColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      ..._highlightKeyValues(line.substring(prefix.length)),
    ];
  }

  /// Highlight key=value pairs and quoted strings within a text fragment.
  List<InlineSpan> _highlightKeyValues(String text) {
    if (text.isEmpty) return [];

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    // Match key=value pairs
    for (final match in _kvRe.allMatches(text)) {
      // Text before this match
      if (match.start > lastEnd) {
        final before = text.substring(lastEnd, match.start);
        spans.addAll(_highlightStrings(before));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(color: _keyColor),
      ));
      spans.add(const TextSpan(
        text: '=',
        style: TextStyle(color: _arrowColor),
      ));
      spans.add(TextSpan(
        text: match.group(2),
        style: const TextStyle(color: _valueColor),
      ));
      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.addAll(_highlightStrings(text.substring(lastEnd)));
    }

    return spans;
  }

  /// Highlight quoted strings within a text fragment.
  static final _quotedRe = RegExp(r"'[^']*'");

  List<InlineSpan> _highlightStrings(String text) {
    if (text.isEmpty) return [];

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _quotedRe.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(color: _stringColor),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    } else if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}
