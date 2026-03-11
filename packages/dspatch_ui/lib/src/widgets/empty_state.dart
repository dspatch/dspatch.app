import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A composable empty/blank state component inspired by shadcn/ui Empty.
///
/// Use convenience props for quick setup:
/// ```dart
/// EmptyState(
///   icon: LucideIcons.inbox,
///   title: 'No messages',
///   description: 'You have no messages yet.',
///   actions: [Button(label: 'Compose', onPressed: () {})],
/// )
/// ```
///
/// Or compose with sub-components for full control:
/// ```dart
/// EmptyState.custom(
///   child: Column(children: [
///     EmptyIcon(icon: LucideIcons.inbox),
///     EmptyTitle(text: 'No messages'),
///     EmptyDescription(text: 'You have no messages yet.'),
///     EmptyActions(children: [Button(label: 'Compose')]),
///   ]),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Creates an empty state with standard icon/title/description/actions layout.
  const EmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    this.title,
    this.description,
    this.actions,
    this.compact = false,
  }) : child = null;

  /// Creates an empty state with a fully custom child layout.
  const EmptyState.custom({
    super.key,
    required this.child,
    this.compact = false,
  })  : icon = null,
        iconWidget = null,
        title = null,
        description = null,
        actions = null;

  /// Icon to display in the media area.
  final IconData? icon;

  /// Custom widget to display instead of [icon].
  final Widget? iconWidget;

  /// Primary heading text.
  final String? title;

  /// Supporting description text.
  final String? description;

  /// Action widgets (buttons) shown below the description.
  final List<Widget>? actions;

  /// Whether to use reduced spacing.
  final bool compact;

  /// Fully custom child — used by [EmptyState.custom].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? Spacing.sm : Spacing.lg;

    if (child != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? Spacing.lg : Spacing.xxl),
          child: child,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? Spacing.lg : Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              EmptyIcon(icon: icon!, compact: compact),
            if ((icon != null || iconWidget != null) &&
                (title != null || description != null))
              SizedBox(height: gap),
            if (title != null) EmptyTitle(text: title!, compact: compact),
            if (description != null) ...[
              const SizedBox(height: Spacing.xs),
              EmptyDescription(text: description!),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: gap),
              EmptyActions(children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon display for an empty state — rounded muted background.
class EmptyIcon extends StatelessWidget {
  const EmptyIcon({
    super.key,
    required this.icon,
    this.compact = false,
  });

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(
        icon,
        size: compact ? 18 : 22,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

/// Heading text for an empty state.
class EmptyTitle extends StatelessWidget {
  const EmptyTitle({super.key, required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: compact ? 14 : 15,
        fontWeight: FontWeight.w500,
        color: AppColors.foreground,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Description text for an empty state — muted, constrained width.
class EmptyDescription extends StatelessWidget {
  const EmptyDescription({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.mutedForeground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Action row for an empty state — centred wrap of buttons.
class EmptyActions extends StatelessWidget {
  const EmptyActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      alignment: WrapAlignment.center,
      children: children,
    );
  }
}
