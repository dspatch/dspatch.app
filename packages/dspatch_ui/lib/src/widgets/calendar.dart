import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Selection mode for [Calendar].
enum CalendarMode { single, multiple, range }

/// A month calendar grid inspired by shadcn/ui Calendar.
///
/// ```dart
/// Calendar(
///   selected: {DateTime(2024, 1, 15)},
///   onChanged: (dates) => setState(() => _selected = dates),
/// )
/// ```
class Calendar extends StatefulWidget {
  const Calendar({
    super.key,
    this.selected = const {},
    this.onChanged,
    this.mode = CalendarMode.single,
    this.initialMonth,
  });

  /// Currently selected date(s).
  final Set<DateTime> selected;

  /// Called when selection changes.
  final ValueChanged<Set<DateTime>>? onChanged;

  /// Selection mode.
  final CalendarMode mode;

  /// Initial displayed month. Defaults to now.
  final DateTime? initialMonth;

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = widget.initialMonth ?? DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + 1,
      );
    });
  }

  void _onDayTap(DateTime day) {
    if (widget.onChanged == null) return;

    final newSelected = Set<DateTime>.from(widget.selected);

    if (widget.mode == CalendarMode.single) {
      newSelected
        ..clear()
        ..add(day);
    } else if (widget.mode == CalendarMode.multiple) {
      if (newSelected.any((d) => _isSameDay(d, day))) {
        newSelected.removeWhere((d) => _isSameDay(d, day));
      } else {
        newSelected.add(day);
      }
    } else {
      // Range: first tap sets start, second tap sets end
      if (newSelected.length == 1) {
        final start = newSelected.first;
        if (day.isBefore(start)) {
          newSelected
            ..clear()
            ..add(day);
        } else {
          newSelected.add(day);
        }
      } else {
        newSelected
          ..clear()
          ..add(day);
      }
    }

    widget.onChanged!(newSelected);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelected(DateTime day) =>
      widget.selected.any((d) => _isSameDay(d, day));

  bool _isInRange(DateTime day) {
    if (widget.mode != CalendarMode.range || widget.selected.length != 2) {
      return false;
    }
    final sorted = widget.selected.toList()..sort();
    return day.isAfter(sorted.first) && day.isBefore(sorted.last);
  }

  bool _isToday(DateTime day) => _isSameDay(day, DateTime.now());

  static const _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<DateTime?> _getDaysInGrid() {
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
    ).day;

    // Monday = 1, Sunday = 7
    final startWeekday = first.weekday;
    final leadingNulls = startWeekday - 1;

    final days = <DateTime?>[];
    for (int i = 0; i < leadingNulls; i++) {
      days.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_displayMonth.year, _displayMonth.month, d));
    }
    // Pad to fill last row
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInGrid();

    return SizedBox(
      width: 7 * 36.0 + 6 * Spacing.xs,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(LucideIcons.chevron_left, size: 18, color: AppColors.mutedForeground),
                ),
              ),
              Text(
                '${_months[_displayMonth.month - 1]} ${_displayMonth.year}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(LucideIcons.chevron_right, size: 18, color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Weekday headers
          Row(
            children: [
              for (final wd in _weekDays)
                SizedBox(
                  width: 36,
                  height: 28,
                  child: Center(
                    child: Text(
                      wd,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Day grid
          for (int row = 0; row < days.length ~/ 7; row++)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  for (int col = 0; col < 7; col++)
                    _buildDayCell(days[row * 7 + col]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime? day) {
    if (day == null) {
      return const SizedBox(width: 36, height: 36);
    }

    final selected = _isSelected(day);
    final inRange = _isInRange(day);
    final today = _isToday(day);

    return GestureDetector(
      onTap: () => _onDayTap(day),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : inRange
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: today && !selected
                ? Border.all(color: AppColors.border)
                : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected || today ? FontWeight.w600 : null,
                color: selected
                    ? AppColors.primaryForeground
                    : AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
