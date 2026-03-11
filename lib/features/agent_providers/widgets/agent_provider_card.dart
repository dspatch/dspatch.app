// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import '../../../core/utils/datetime_ext.dart';
import '../models/agent_list_item.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';


class AgentProviderCard extends StatelessWidget {
  final AgentListItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onSubmitToHub;
  final VoidCallback? onClone;

  const AgentProviderCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onSubmitToHub,
    this.onClone,
  });

  @override
  Widget build(BuildContext context) {
    final provider = item.provider;
    final isHub = provider?.sourceType == SourceType.hub;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: DspatchCard(
          child: Row(
            children: [
              // Name + description + hub meta
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isTemplate &&
                            isHub &&
                            provider!.hubAuthor != null) ...[
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'by ${provider.hubAuthor}',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (!item.isTemplate &&
                        isHub &&
                        provider!.hubTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            if (provider.hubCategory != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: Spacing.xs),
                                child: DspatchBadge(
                                  label: provider.hubCategory!,
                                  variant: BadgeVariant.secondary,
                                ),
                              ),
                            ...provider.hubTags.take(2).map(
                                  (tag) => Padding(
                                    padding: const EdgeInsets.only(
                                        right: Spacing.xs),
                                    child: DspatchBadge(
                                      label: tag,
                                      variant: BadgeVariant.outline,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Entry point (providers) or source URI (templates)
              Expanded(
                flex: 2,
                child: Text(
                  item.isTemplate
                      ? item.template!.sourceUri
                      : provider!.entryPoint,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontFamily: AppFonts.mono,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Required env count (providers only)
              if (!item.isTemplate && provider!.requiredEnv.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: _MetaChip(
                    icon: LucideIcons.key,
                    value: '${provider.requiredEnv.length}',
                  ),
                ),

              // Hub version (providers only)
              if (!item.isTemplate &&
                  isHub &&
                  provider!.hubVersion != null)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: Text(
                    'v${provider.hubVersion}',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                ),

              // Source badge (providers) or Template badge (templates)
              if (item.isTemplate)
                const DspatchBadge(
                  label: 'Template',
                  variant: BadgeVariant.secondary,
                )
              else
                DspatchBadge(
                  label: switch (provider!.sourceType) {
                    SourceType.local => 'Local',
                    SourceType.git => 'Git',
                    SourceType.hub => 'Hub',
                  },
                  variant: switch (provider.sourceType) {
                    SourceType.local => BadgeVariant.secondary,
                    SourceType.git => BadgeVariant.outline,
                    SourceType.hub => BadgeVariant.info,
                  },
                ),
              const SizedBox(width: Spacing.md),

              // Updated time
              SizedBox(
                width: 52,
                child: Text(
                  item.updatedAt.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: Spacing.sm),

              // Actions
              if (!item.isTemplate && isHub) ...[
                DspatchIconButton(
                  icon: LucideIcons.eye,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'View',
                  onPressed: onTap,
                ),
                if (onClone != null)
                  DspatchIconButton(
                    icon: LucideIcons.copy,
                    variant: IconButtonVariant.ghost,
                    size: IconButtonSize.sm,
                    tooltip: 'Clone to local',
                    onPressed: onClone,
                  ),
              ] else
                DspatchIconButton(
                  icon: LucideIcons.pencil,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'Edit',
                  onPressed: onTap,
                ),
              if (onSubmitToHub != null)
                DspatchIconButton(
                  icon: LucideIcons.upload,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'Submit to Hub',
                  onPressed: onSubmitToHub,
                ),
              DspatchIconButton(
                icon: LucideIcons.trash_2,
                variant: IconButtonVariant.ghost,
                size: IconButtonSize.sm,
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.mutedForeground),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 11,
            fontFamily: AppFonts.mono,
          ),
        ),
      ],
    );
  }
}
