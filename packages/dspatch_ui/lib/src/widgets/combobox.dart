import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A searchable select (combobox) inspired by shadcn/ui Combobox.
///
/// ```dart
/// Combobox<String>(
///   items: [
///     ComboboxItem(value: 'next', label: 'Next.js'),
///     ComboboxItem(value: 'svelte', label: 'SvelteKit'),
///     ComboboxItem(value: 'nuxt', label: 'Nuxt.js'),
///   ],
///   value: _selected,
///   onChanged: (value) => setState(() => _selected = value),
///   placeholder: 'Select framework...',
///   searchPlaceholder: 'Search framework...',
/// )
/// ```
class Combobox<T> extends StatefulWidget {
  const Combobox({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.placeholder = 'Select...',
    this.searchPlaceholder = 'Search...',
    this.emptyText = 'No results found.',
    this.width = 200,
  });

  /// Available items.
  final List<ComboboxItem<T>> items;

  /// Currently selected value.
  final T? value;

  /// Called when selection changes.
  final ValueChanged<T?>? onChanged;

  /// Placeholder when nothing is selected.
  final String placeholder;

  /// Placeholder for the search input.
  final String searchPlaceholder;

  /// Text shown when search yields no results.
  final String emptyText;

  /// Trigger and popover width.
  final double width;

  @override
  State<Combobox<T>> createState() => _ComboboxState<T>();
}

/// Data for a combobox item.
class ComboboxItem<T> {
  const ComboboxItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class _ComboboxState<T> extends State<Combobox<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  final _searchController = TextEditingController();

  void _toggle() {
    if (_entry != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _searchController.clear();
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _select(T value) {
    widget.onChanged?.call(value == widget.value ? null : value);
    _close();
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
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
          offset: const Offset(0, 4),
          child: _ComboboxPopover<T>(
            items: widget.items,
            value: widget.value,
            searchPlaceholder: widget.searchPlaceholder,
            emptyText: widget.emptyText,
            width: widget.width,
            onSelect: _select,
          ),
        ),
      ],
    );
  }

  String get _displayText {
    if (widget.value == null) return widget.placeholder;
    final item = widget.items.cast<ComboboxItem<T>?>().firstWhere(
          (i) => i!.value == widget.value,
          orElse: () => null,
        );
    return item?.label ?? widget.placeholder;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _entry != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.input),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.value != null
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isOpen
                      ? LucideIcons.chevron_up
                      : LucideIcons.chevron_down,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComboboxPopover<T> extends StatefulWidget {
  const _ComboboxPopover({
    required this.items,
    required this.value,
    required this.searchPlaceholder,
    required this.emptyText,
    required this.width,
    required this.onSelect,
  });

  final List<ComboboxItem<T>> items;
  final T? value;
  final String searchPlaceholder;
  final String emptyText;
  final double width;
  final ValueChanged<T> onSelect;

  @override
  State<_ComboboxPopover<T>> createState() => _ComboboxPopoverState<T>();
}

class _ComboboxPopoverState<T> extends State<_ComboboxPopover<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where(
                (i) => i.label.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Material(
      color: AppColors.popover,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 4,
      child: Container(
        width: widget.width,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.foreground,
                ),
                cursorColor: AppColors.foreground,
                decoration: InputDecoration(
                  hintText: widget.searchPlaceholder,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 16,
                    color: AppColors.mutedForeground,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 0,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.sm,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(height: 1, color: AppColors.border),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(
                  widget.emptyText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in filtered)
                        _ComboboxItemWidget<T>(
                          item: item,
                          isSelected: item.value == widget.value,
                          onTap: () => widget.onSelect(item.value),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComboboxItemWidget<T> extends StatefulWidget {
  const _ComboboxItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ComboboxItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ComboboxItemWidget<T>> createState() => _ComboboxItemWidgetState<T>();
}

class _ComboboxItemWidgetState<T> extends State<_ComboboxItemWidget<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
          color: _hovered ? AppColors.surfaceHover : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: widget.isSelected
                    ? const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.foreground,
                      )
                    : null,
              ),
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
