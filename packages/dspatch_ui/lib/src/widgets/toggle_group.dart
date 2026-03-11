import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'toggle.dart';

/// Selection mode for [ToggleGroup].
enum ToggleGroupType { single, multiple }

/// Visual style for the [ToggleGroup] container.
enum ToggleGroupStyle {
  /// Individual separated buttons with spacing (default).
  separated,

  /// Grouped segmented control with shared background (tabs-like).
  grouped,
}

/// A group of toggles inspired by shadcn/ui ToggleGroup.
///
/// ```dart
/// ToggleGroup(
///   type: ToggleGroupType.single,
///   value: {_selected},
///   onChanged: (v) => setState(() => _selected = v.first),
///   children: [
///     ToggleGroupItem(value: 'bold', child: Icon(LucideIcons.bold)),
///     ToggleGroupItem(value: 'italic', child: Icon(LucideIcons.italic)),
///     ToggleGroupItem(value: 'underline', child: Icon(LucideIcons.underline)),
///   ],
/// )
///
/// // Text labels with grouped style
/// ToggleGroup(
///   style: ToggleGroupStyle.grouped,
///   iconMode: false,
///   value: {'center'},
///   onChanged: (v) => setState(() => ...),
///   children: [
///     ToggleGroupItem(value: 'left', label: 'Left'),
///     ToggleGroupItem(value: 'center', label: 'Center'),
///     ToggleGroupItem(value: 'right', label: 'Right'),
///   ],
/// )
/// ```
class ToggleGroup extends StatelessWidget {
  const ToggleGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.type = ToggleGroupType.single,
    this.variant = ToggleVariant.defaultVariant,
    this.size = ToggleSize.md,
    this.spacing = 2.0,
    this.style = ToggleGroupStyle.separated,
    this.iconMode = true,
  });

  /// Currently selected values.
  final Set<String> value;

  /// Called when selection changes.
  final ValueChanged<Set<String>> onChanged;

  /// Toggle items.
  final List<ToggleGroupItem> children;

  /// Single or multiple selection.
  final ToggleGroupType type;

  /// Visual variant applied to all items.
  final ToggleVariant variant;

  /// Size applied to all items.
  final ToggleSize size;

  /// Spacing between items (only used in [ToggleGroupStyle.separated]).
  final double spacing;

  /// Container style.
  final ToggleGroupStyle style;

  /// When true (default), items are fixed square size for icons or single
  /// characters. When false, items use flexible width for text labels.
  final bool iconMode;

  void _onItemToggled(String itemValue, bool pressed) {
    final newValue = Set<String>.from(value);

    if (type == ToggleGroupType.single) {
      if (pressed) {
        newValue
          ..clear()
          ..add(itemValue);
      } else {
        newValue.remove(itemValue);
      }
    } else {
      if (pressed) {
        newValue.add(itemValue);
      } else {
        newValue.remove(itemValue);
      }
    }

    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      ToggleGroupStyle.separated => _buildSeparated(),
      ToggleGroupStyle.grouped => _buildGrouped(),
    };
  }

  Widget _buildSeparated() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Toggle(
            pressed: value.contains(children[i].value),
            onChanged: (pressed) =>
                _onItemToggled(children[i].value, pressed),
            variant: variant,
            size: size,
            iconMode: iconMode,
            child: children[i]._content,
          ),
        ],
      ],
    );
  }

  Widget _buildGrouped() {
    final hasBorder = variant == ToggleVariant.outline ||
        variant == ToggleVariant.primary;
    final dim = switch (size) {
      ToggleSize.sm => 32.0,
      ToggleSize.md => 36.0,
      ToggleSize.lg => 40.0,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            hasBorder ? Border.all(color: AppColors.input, width: 1) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0 && hasBorder)
              SizedBox(
                width: 1,
                height: dim,
                child: const ColoredBox(color: AppColors.input),
              ),
            _JoinedItem(
              isActive: value.contains(children[i].value),
              onTap: () => _onItemToggled(
                  children[i].value, !value.contains(children[i].value)),
              variant: variant,
              size: size,
              iconMode: iconMode,
              child: children[i]._content,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Joined item ───────────────────────────────────────────────────────────

class _JoinedItem extends StatefulWidget {
  const _JoinedItem({
    required this.isActive,
    required this.onTap,
    required this.variant,
    required this.size,
    required this.iconMode,
    required this.child,
  });

  final bool isActive;
  final VoidCallback onTap;
  final ToggleVariant variant;
  final ToggleSize size;
  final bool iconMode;
  final Widget child;

  @override
  State<_JoinedItem> createState() => _JoinedItemState();
}

class _JoinedItemState extends State<_JoinedItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (widget.isActive) {
      bg = _activeBg;
      fg = _activeFg;
    } else if (_hovered) {
      bg = AppColors.surfaceHover;
      fg = AppColors.mutedForeground;
    } else {
      bg = Colors.transparent;
      fg = AppColors.mutedForeground;
    }

    final dim = switch (widget.size) {
      ToggleSize.sm => 32.0,
      ToggleSize.md => 36.0,
      ToggleSize.lg => 40.0,
    };

    final hPadding = switch (widget.size) {
      ToggleSize.sm => Spacing.sm,
      ToggleSize.md => Spacing.md,
      ToggleSize.lg => Spacing.lg,
    };

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: dim,
          width: widget.iconMode ? dim : null,
          padding: widget.iconMode
              ? null
              : EdgeInsets.symmetric(horizontal: hPadding),
          color: bg,
          child: IconTheme(
            data: IconThemeData(color: fg, size: 16),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg,
                fontFamily: AppFonts.sans,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }

  Color get _activeBg => switch (widget.variant) {
        ToggleVariant.defaultVariant => AppColors.surfaceHover,
        ToggleVariant.outline => AppColors.surfaceHover,
        ToggleVariant.primary => AppColors.primary,
        ToggleVariant.secondary => AppColors.secondary,
        ToggleVariant.destructive => AppColors.destructive,
        ToggleVariant.ghost => AppColors.surfaceHover,
        ToggleVariant.accentOutline => AppColors.accentMuted,
      };

  Color get _activeFg => switch (widget.variant) {
        ToggleVariant.defaultVariant => AppColors.foreground,
        ToggleVariant.outline => AppColors.foreground,
        ToggleVariant.primary => AppColors.primaryForeground,
        ToggleVariant.secondary => AppColors.secondaryForeground,
        ToggleVariant.destructive => AppColors.destructiveForeground,
        ToggleVariant.ghost => AppColors.foreground,
        ToggleVariant.accentOutline => AppColors.primaryForeground,
      };
}

/// A single item within a [ToggleGroup].
class ToggleGroupItem extends StatelessWidget {
  const ToggleGroupItem({
    super.key,
    required this.value,
    this.child,
    this.label,
  }) : assert(child != null || label != null,
            'Either child or label must be provided');

  /// Unique value for this item.
  final String value;

  /// Content widget (typically an icon). Mutually exclusive with [label].
  final Widget? child;

  /// Text label. Mutually exclusive with [child].
  final String? label;

  /// Resolved content: [child] takes priority over [label].
  Widget get _content => child ?? Text(label!);

  @override
  Widget build(BuildContext context) {
    // Rendered by ToggleGroup, this build is not directly used.
    return _content;
  }
}
