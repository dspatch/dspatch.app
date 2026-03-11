// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dspatch_ui/dspatch_ui.dart';

/// Markdown renderer styled with the d:spatch theme.
///
/// Renders agent messages and inquiry content. Uses [MarkdownBody]
/// for inline display (no scrolling — parent handles scrolling).
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.selectable = true,
    this.compact = false,
  });

  final String data;
  final bool selectable;

  /// When true, renders with smaller font sizes suitable for inline cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pSize = compact ? 12.0 : 14.0;
    final h1Size = compact ? 18.0 : 24.0;
    final h2Size = compact ? 15.0 : 20.0;
    final h3Size = compact ? 13.0 : 16.0;
    final h4Size = compact ? 12.0 : 14.0;
    final codeSize = compact ? 11.0 : 13.0;

    return MarkdownBody(
      data: data,
      selectable: selectable,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: AppColors.foreground, fontSize: pSize, height: 1.6),
        h1: TextStyle(color: AppColors.foreground, fontSize: h1Size, fontWeight: FontWeight.w700),
        h2: TextStyle(color: AppColors.foreground, fontSize: h2Size, fontWeight: FontWeight.w600),
        h3: TextStyle(color: AppColors.foreground, fontSize: h3Size, fontWeight: FontWeight.w600),
        h4: TextStyle(color: AppColors.foreground, fontSize: h4Size, fontWeight: FontWeight.w600),
        code: TextStyle(
          color: AppColors.foreground,
          backgroundColor: AppColors.muted,
          fontFamily: AppFonts.mono,
          fontSize: codeSize,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        codeblockPadding: const EdgeInsets.all(Spacing.md),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.border, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: Spacing.md),
        listBullet: TextStyle(color: AppColors.mutedForeground, fontSize: pSize),
        a: TextStyle(color: AppColors.primary, fontSize: pSize, decoration: TextDecoration.underline),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        tableBorder: TableBorder.all(color: AppColors.border, width: 1),
        tableHead: TextStyle(color: AppColors.foreground, fontSize: pSize, fontWeight: FontWeight.w600),
        tableBody: TextStyle(color: AppColors.foreground, fontSize: pSize),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      ),
    );
  }
}
