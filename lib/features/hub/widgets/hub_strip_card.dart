// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import 'hub_like_button.dart';

/// Compact card for the inline hub strip. Shows essential info only.
class HubStripCard extends StatelessWidget {
  const HubStripCard({
    super.key,
    required this.name,
    this.author,
    required this.slug,
    required this.targetType,
    required this.likes,
    required this.userLiked,
    required this.downloads,
    required this.verified,
    required this.actionLabel,
    required this.actionIcon,
    this.isLoading = false,
    required this.onAction,
  });

  final String name;
  final String? author;
  final String slug;
  final String targetType;
  final int likes;
  final bool userLiked;
  final int downloads;
  final bool verified;
  final String actionLabel;
  final IconData actionIcon;
  final bool isLoading;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DspatchCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name + verified
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: Spacing.xs),
                  const Icon(LucideIcons.badge_check,
                      size: 13, color: AppColors.primary),
                ],
              ],
            ),

            // Author
            if (author != null) ...[
              const SizedBox(height: 2),
              Text(
                'by $author',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: Spacing.sm),

            // Like button + downloads + action
            Row(
              children: [
                HubLikeButton(
                  slug: slug,
                  author: author,
                  targetType: targetType,
                  initialLikes: likes,
                  initialLiked: userLiked,
                ),
                const SizedBox(width: Spacing.sm),
                Icon(LucideIcons.download,
                    size: 12, color: AppColors.mutedForeground.withValues(alpha: 0.5)),
                const SizedBox(width: 2),
                Text(
                  '$downloads',
                  style: TextStyle(
                    color: AppColors.mutedForeground.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Button(
                  label: actionLabel,
                  icon: actionIcon,
                  size: ButtonSize.xs,
                  loading: isLoading,
                  onPressed: onAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact tile card for the Community Hub grid section.
class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.name,
    this.author,
    this.description,
    required this.slug,
    required this.targetType,
    required this.likes,
    required this.userLiked,
    required this.downloads,
    required this.verified,
    this.category,
    required this.onTap,
  });

  final String name;
  final String? author;
  final String? description;
  final String slug;
  final String targetType;
  final int likes;
  final bool userLiked;
  final int downloads;
  final bool verified;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: DspatchCard(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name + verified
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: Spacing.xs),
                    const Icon(LucideIcons.badge_check,
                        size: 13, color: AppColors.primary),
                  ],
                ],
              ),

              // Author
              if (author != null) ...[
                const SizedBox(height: 2),
                Text(
                  'by $author',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Description
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Flexible(
                  child: Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: Spacing.xs),

              // Bottom row: like button + downloads + category badge
              Row(
                children: [
                  HubLikeButton(
                    slug: slug,
                    author: author,
                    targetType: targetType,
                    initialLikes: likes,
                    initialLiked: userLiked,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Icon(LucideIcons.download,
                      size: 12, color: AppColors.mutedForeground.withValues(alpha: 0.5)),
                  const SizedBox(width: 2),
                  Text(
                    '$downloads',
                    style: TextStyle(
                      color: AppColors.mutedForeground.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  if (category != null) ...[
                    const Spacer(),
                    DspatchBadge(
                      label: category!,
                      variant: BadgeVariant.secondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
