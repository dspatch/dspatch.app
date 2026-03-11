import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A container with border and background inspired by shadcn/ui Card.
///
/// Use the convenience [title]/[description] props for simple cards, or
/// compose with [CardHeader], [CardContent], and [CardFooter] for full control:
///
/// ```dart
/// DspatchCard(title: 'Stats', child: Text('Simple'))
///
/// DspatchCard(
///   padding: EdgeInsets.zero,
///   child: Column(
///     children: [
///       CardHeader(child: Column(children: [
///         CardTitle(text: 'Account'),
///         CardDescription(text: 'Manage your account settings'),
///       ])),
///       CardContent(child: Text('Content here')),
///       CardFooter(child: Button(label: 'Save')),
///     ],
///   ),
/// )
/// ```
class DspatchCard extends StatelessWidget {
  const DspatchCard({
    super.key,
    this.title,
    this.description,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
  });

  /// Convenience heading rendered above [child].
  final String? title;

  /// Convenience description rendered below [title].
  final String? description;

  /// Card body.
  final Widget child;

  /// Padding around the card content.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              CardTitle(text: title!),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: CardDescription(text: description!),
                ),
              const SizedBox(height: Spacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Header area with padding for card title/description.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, Spacing.lg),
      child: child,
    );
  }
}

/// Card heading text — 15 px, semibold.
class CardTitle extends StatelessWidget {
  const CardTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.foreground,
      ),
    );
  }
}

/// Card description text — 12 px, muted.
class CardDescription extends StatelessWidget {
  const CardDescription({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

/// Padded body area for card content.
class CardContent extends StatelessWidget {
  const CardContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Horizontal footer with padding for actions.
class CardFooter extends StatelessWidget {
  const CardFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Spacing.lg, 0, 0),
      child: Row(children: [child]),
    );
  }
}
