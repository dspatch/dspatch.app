// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Empty state shown when no agent templates exist at all.
class AgentProviderListEmpty extends StatelessWidget {
  const AgentProviderListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.cpu,
      title: 'No agent templates yet',
      description: 'Create your first reusable agent template.'
    );
  }
}

/// Empty state shown when a search query returns no matching templates.
class AgentProviderSearchEmpty extends StatelessWidget {
  const AgentProviderSearchEmpty({
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
      description: 'No templates match "$query".',
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
