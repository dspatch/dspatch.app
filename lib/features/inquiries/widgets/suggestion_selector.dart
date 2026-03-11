// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

class SuggestionSelector extends StatelessWidget {
  const SuggestionSelector({
    super.key,
    required this.suggestions,
    required this.selectedIndex,
    required this.onSelected,
    this.readOnly = false,
  });

  final List<({String text, bool isRecommended})> suggestions;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < suggestions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: GestureDetector(
              onTap: readOnly
                  ? null
                  : () => onSelected(selectedIndex == i ? null : i),
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? (readOnly
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : Colors.transparent,
                  border: Border.all(
                    color: selectedIndex == i
                        ? (readOnly ? AppColors.success : AppColors.primary)
                        : suggestions[i].isRecommended && !readOnly
                            ? AppColors.accent
                            : AppColors.border,
                    width: selectedIndex == i ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedIndex == i
                          ? (readOnly
                              ? LucideIcons.circle_check
                              : LucideIcons.circle_dot)
                          : LucideIcons.circle,
                      size: 18,
                      color: selectedIndex == i
                          ? (readOnly
                              ? AppColors.success
                              : AppColors.primary)
                          : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        suggestions[i].text,
                        style: TextStyle(
                          color: selectedIndex == i && readOnly
                              ? AppColors.foreground
                              : readOnly
                                  ? AppColors.mutedForeground
                                  : AppColors.foreground,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (selectedIndex == i && readOnly)
                      const DspatchBadge(
                        label: 'Selected',
                        variant: BadgeVariant.success,
                      )
                    else if (suggestions[i].isRecommended)
                      const DspatchBadge(
                        label: 'Recommended',
                        variant: BadgeVariant.info,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
