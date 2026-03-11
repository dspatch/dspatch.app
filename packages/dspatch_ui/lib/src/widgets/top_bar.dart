import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A shell header bar with configurable leading, title, center, and trailing
/// slots.
///
/// ```dart
/// TopBar(
///   leading: Button(
///     variant: ButtonVariant.ghost,
///     size: ButtonSize.icon,
///     icon: LucideIcons.menu,
///     onPressed: toggleSidebar,
///   ),
///   title: Breadcrumb(items: breadcrumbItems),
///   trailing: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [notificationIcon, avatarWidget],
///   ),
/// )
/// ```
class TopBar extends StatelessWidget {
  /// Widget shown at the leading (left) edge — typically a menu toggle button.
  final Widget? leading;

  /// Widget shown after the leading slot — typically breadcrumbs or a title.
  /// Takes its intrinsic width; remaining space goes to [center] or stays
  /// empty.
  final Widget? title;

  /// Optional widget that fills the remaining horizontal space between
  /// [title] and [trailing]. When null the space is left empty.
  final Widget? center;

  /// Widget shown at the trailing (right) edge — typically action buttons.
  final Widget? trailing;

  /// Bar height. Defaults to 48 logical pixels.
  final double height;

  /// Visual decoration. When null a default dark card background with a
  /// 1 px bottom border is used.
  final BoxDecoration? decoration;

  /// Inner padding. Defaults to 8 px horizontal.
  final EdgeInsetsGeometry padding;

  const TopBar({
    super.key,
    this.leading,
    this.title,
    this.center,
    this.trailing,
    this.height = 48,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.sm),
  });

  static final _defaultDecoration = BoxDecoration(
    color: AppColors.card,
    border: const Border(
      bottom: BorderSide(color: AppColors.border, width: 1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: decoration ?? _defaultDecoration,
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Spacing.xs)],
          ?title,
          if (center != null) Expanded(child: center!) else const Spacer(),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
