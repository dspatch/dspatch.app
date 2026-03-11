import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A generic radio group inspired by shadcn/ui RadioGroup.
///
/// ```dart
/// RadioGroup<String>(
///   value: _selected,
///   onChanged: (v) => setState(() => _selected = v),
///   children: [
///     RadioGroupItem(value: 'a', label: 'Option A'),
///     RadioGroupItem(value: 'b', label: 'Option B'),
///     RadioGroupItem(value: 'c', label: 'Option C'),
///   ],
/// )
/// ```
class RadioGroup<T> extends StatelessWidget {
  const RadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.direction = Axis.vertical,
    this.spacing = Spacing.sm,
  });

  /// Currently selected value.
  final T? value;

  /// Called when selection changes.
  final ValueChanged<T> onChanged;

  /// Radio items.
  final List<RadioGroupItem<T>> children;

  /// Layout direction.
  final Axis direction;

  /// Spacing between items.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      value: value,
      onChanged: onChanged,
      child: direction == Axis.vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  children[i],
                ],
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  children[i],
                ],
              ],
            ),
    );
  }
}

/// A single radio item within a [RadioGroup].
class RadioGroupItem<T> extends StatelessWidget {
  const RadioGroupItem({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.disabled = false,
  });

  /// Value this item represents.
  final T value;

  /// Label text.
  final String label;

  /// Optional description below the label.
  final String? description;

  /// Whether the item is disabled.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scope = _RadioGroupScope.of<T>(context);
    final selected = scope.value == value;

    return GestureDetector(
      onTap: disabled ? null : () => scope.onChanged(value),
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioDot(selected: selected, disabled: disabled),
            const SizedBox(width: Spacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: disabled
                        ? AppColors.mutedForeground
                        : AppColors.foreground,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.disabled});

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : disabled
                  ? AppColors.muted
                  : AppColors.input,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class _RadioGroupScope<T> extends InheritedWidget {
  const _RadioGroupScope({
    required this.value,
    required this.onChanged,
    required super.child,
  });

  final T? value;
  final ValueChanged<T> onChanged;

  static _RadioGroupScope<T> of<T>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>();
    assert(scope != null, 'No RadioGroup<$T> found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(_RadioGroupScope<T> oldWidget) =>
      value != oldWidget.value;
}
