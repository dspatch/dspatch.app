// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Empty state shown when no workspaces exist at all.
class WorkspaceListEmpty extends StatelessWidget {
  const WorkspaceListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.layout_grid,
      title: 'No workspaces yet',
      description: 'Create a workspace to orchestrate your agents.'
    );
  }
}

/// Empty state shown when a search or filter returns no matching workspaces.
class WorkspaceSearchEmpty extends StatelessWidget {
  const WorkspaceSearchEmpty({
    super.key,
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.search_x,
      title: 'No matches',
      description: 'No workspaces match "$query".',
      actions: [
        Button(
          label: 'Clear Search',
          variant: ButtonVariant.outline,
          onPressed: onClear,
        ),
      ],
    );
  }
}
