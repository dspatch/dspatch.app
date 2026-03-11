import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'calendar.dart';

/// A date picker that combines a Button trigger with a Popover + Calendar,
/// inspired by shadcn/ui DatePicker.
///
/// ```dart
/// DatePicker(
///   value: _selectedDate,
///   onChanged: (date) => setState(() => _selectedDate = date),
///   placeholder: 'Pick a date',
/// )
/// ```
class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    this.value,
    this.onChanged,
    this.placeholder = 'Pick a date',
    this.mode = CalendarMode.single,
    this.width = 280,
  });

  /// Currently selected date (for single mode).
  final DateTime? value;

  /// Called when the date changes.
  final ValueChanged<DateTime?>? onChanged;

  /// Placeholder text when no date is selected.
  final String placeholder;

  /// Calendar selection mode.
  final CalendarMode mode;

  /// Trigger button width.
  final double width;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _toggle() {
    if (_entry != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _onDateChanged(Set<DateTime> dates) {
    if (widget.mode == CalendarMode.single) {
      widget.onChanged?.call(dates.isEmpty ? null : dates.first);
      _close();
    }
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
          offset: const Offset(0, Spacing.xs),
          child: Material(
            color: AppColors.popover,
            borderRadius: BorderRadius.circular(AppRadius.md),
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.all(Spacing.md),
              child: Calendar(
                selected:
                    widget.value != null ? {widget.value!} : const {},
                onChanged: _onDateChanged,
                mode: widget.mode,
                initialMonth: widget.value,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _entry != null;
    final hasValue = widget.value != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            width: widget.width,
            padding:
                const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isOpen ? AppColors.ring : AppColors.input,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    hasValue
                        ? _formatDate(widget.value!)
                        : widget.placeholder,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
