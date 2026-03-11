import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A generic list/menu item with leading, title, description, and trailing,
/// inspired by shadcn/ui Item.
///
/// ```dart
/// Item(
///   leading: Icon(LucideIcons.user),
///   title: 'John Doe',
///   description: 'john@example.com',
///   trailing: Icon(LucideIcons.chevron_right),
///   onTap: () {},
/// )
/// ```
class Item extends StatefulWidget {
  const Item({
    super.key,
    this.leading,
    this.title,
    this.description,
    this.trailing,
    this.onTap,
    this.padding,
  });

  /// Leading widget (icon, avatar, etc.).
  final Widget? leading;

  /// Primary text.
  final String? title;

  /// Secondary text shown below [title].
  final String? description;

  /// Trailing widget (icon, badge, etc.).
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Custom padding (defaults to 12 horizontal, 10 vertical).
  final EdgeInsets? padding;

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.mutedForeground,
                    size: 18,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foreground,
                        ),
                      ),
                    if (widget.description != null)
                      Text(
                        widget.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: Spacing.sm),
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.mutedForeground,
                    size: 16,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
