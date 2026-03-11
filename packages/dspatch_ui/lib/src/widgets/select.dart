import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A single selectable option.
class SelectItem<T> {
  const SelectItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A labelled group of [SelectItem]s.
class SelectGroup<T> {
  const SelectGroup({required this.label, required this.items});

  final String label;
  final List<SelectItem<T>> items;
}

/// A styled dropdown select inspired by shadcn/ui Select.
///
/// Uses a custom overlay popover instead of Material's DropdownButton
/// for a cleaner, more consistent look.
///
/// ```dart
/// Select<String>(
///   value: _selected,
///   hint: 'Pick one',
///   items: [
///     SelectItem(value: 'a', label: 'Alpha'),
///     SelectItem(value: 'b', label: 'Beta'),
///   ],
///   onChanged: (v) => setState(() => _selected = v),
/// )
/// ```
class Select<T> extends StatefulWidget {
  const Select({
    super.key,
    required this.value,
    this.items = const [],
    this.groups = const [],
    required this.onChanged,
    this.hint,
    this.width,
  });

  /// Currently selected value.
  final T? value;

  /// Flat list of options (use [groups] for grouped layout).
  final List<SelectItem<T>> items;

  /// Grouped options rendered with section headers.
  final List<SelectGroup<T>> groups;

  /// Callback when selection changes.
  final ValueChanged<T?> onChanged;

  /// Placeholder text when nothing is selected.
  final String? hint;

  /// Fixed width for the trigger.
  final double? width;

  @override
  State<Select<T>> createState() => _SelectState<T>();
}

class _SelectState<T> extends State<Select<T>>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _close(animate: false);
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    _animController.forward();
    setState(() => _isOpen = true);
  }

  void _close({bool animate = true}) {
    if (!_isOpen) return;
    if (animate) {
      _animController.reverse().then((_) {
        _entry?.remove();
        _entry = null;
      });
    } else {
      _entry?.remove();
      _entry = null;
    }
    setState(() => _isOpen = false);
  }

  void _select(T value) {
    // Re-selecting the current value clears the selection.
    widget.onChanged(value == widget.value ? null : value);
    _close();
  }

  /// Resolves the label for the current value.
  String? get _selectedLabel {
    if (widget.value == null) return null;

    for (final item in widget.items) {
      if (item.value == widget.value) return item.label;
    }
    for (final group in widget.groups) {
      for (final item in group.items) {
        if (item.value == widget.value) return item.label;
      }
    }
    return null;
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        // Dismiss scrim.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, Spacing.xs),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: _SelectPopover<T>(
              items: widget.items,
              groups: widget.groups,
              selectedValue: widget.value,
              onSelect: _select,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _selectedLabel;

    Widget trigger = CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              _toggle();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _isOpen ? AppColors.ring : AppColors.input,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? widget.hint ?? '',
                    style: TextStyle(
                      color: label != null
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                      fontSize: 13,
                      fontFamily: AppFonts.sans,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    LucideIcons.chevron_down,
                    size: 16,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: trigger);
    }
    return trigger;
  }
}

// ─── Popover panel ─────────────────────────────────────────────────────

class _SelectPopover<T> extends StatelessWidget {
  const _SelectPopover({
    required this.items,
    required this.groups,
    required this.selectedValue,
    required this.onSelect,
  });

  final List<SelectItem<T>> items;
  final List<SelectGroup<T>> groups;
  final T? selectedValue;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 4,
      shadowColor: Colors.black54,
      child: Container(
        constraints: const BoxConstraints(minWidth: 128, maxHeight: 300),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final widgets = <Widget>[];

    // Flat items.
    for (final item in items) {
      widgets.add(_SelectOption<T>(
        item: item,
        isSelected: item.value == selectedValue,
        onTap: () => onSelect(item.value),
      ));
    }

    // Grouped items.
    for (int g = 0; g < groups.length; g++) {
      final group = groups[g];

      // Separator between flat items and first group, or between groups.
      if (widgets.isNotEmpty) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Divider(height: 1, color: AppColors.border),
        ));
      }

      // Group label.
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.sm,
          Spacing.xs,
          Spacing.sm,
          Spacing.xs,
        ),
        child: Text(
          group.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
            letterSpacing: 0.5,
          ),
        ),
      ));

      for (final item in group.items) {
        widgets.add(_SelectOption<T>(
          item: item,
          isSelected: item.value == selectedValue,
          indented: true,
          onTap: () => onSelect(item.value),
        ));
      }
    }

    return widgets;
  }
}

// ─── Single option row ─────────────────────────────────────────────────

class _SelectOption<T> extends StatefulWidget {
  const _SelectOption({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.indented = false,
  });

  final SelectItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool indented;

  @override
  State<_SelectOption<T>> createState() => _SelectOptionState<T>();
}

class _SelectOptionState<T> extends State<_SelectOption<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          padding: EdgeInsets.only(
            left: widget.indented ? Spacing.lg : Spacing.sm,
            right: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.item.label,
              style: TextStyle(
                fontSize: 13,
                color: widget.isSelected
                    ? AppColors.foreground
                    : AppColors.foreground,
                fontWeight:
                    widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                fontFamily: AppFonts.sans,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
