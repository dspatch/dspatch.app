import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A command palette (Cmd+K) inspired by shadcn/ui Command.
///
/// ```dart
/// Command.show(
///   context: context,
///   groups: [
///     CommandGroup(
///       heading: 'Suggestions',
///       items: [
///         CommandItem(icon: LucideIcons.calendar, label: 'Calendar', onSelect: () {}),
///         CommandItem(icon: LucideIcons.smile, label: 'Emoji', onSelect: () {}),
///       ],
///     ),
///     CommandGroup(
///       heading: 'Settings',
///       items: [
///         CommandItem(icon: LucideIcons.user, label: 'Profile', onSelect: () {}),
///         CommandItem(icon: LucideIcons.settings, label: 'Settings', onSelect: () {}),
///       ],
///     ),
///   ],
/// );
/// ```
class Command extends StatelessWidget {
  const Command({
    super.key,
    required this.groups,
    this.placeholder = 'Type a command or search...',
    this.emptyText = 'No results found.',
    this.maxWidth = 500,
  });

  /// Command groups with items.
  final List<CommandGroup> groups;

  /// Search input placeholder.
  final String placeholder;

  /// Text when no results match.
  final String emptyText;

  /// Max dialog width.
  final double maxWidth;

  /// Shows the command palette as a dialog.
  static Future<void> show({
    required BuildContext context,
    required List<CommandGroup> groups,
    String placeholder = 'Type a command or search...',
    String emptyText = 'No results found.',
    double maxWidth = 500,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Command(
        groups: groups,
        placeholder: placeholder,
        emptyText: emptyText,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: AppColors.popover,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: _CommandBody(
                groups: groups,
                placeholder: placeholder,
                emptyText: emptyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A group of command items.
class CommandGroup {
  const CommandGroup({
    this.heading,
    required this.items,
  });

  final String? heading;
  final List<CommandItem> items;
}

/// A single command item.
class CommandItem {
  const CommandItem({
    required this.label,
    this.icon,
    this.shortcut,
    this.onSelect,
    this.keywords = const [],
  });

  final String label;
  final IconData? icon;
  final String? shortcut;
  final VoidCallback? onSelect;
  final List<String> keywords;
}

class _CommandBody extends StatefulWidget {
  const _CommandBody({
    required this.groups,
    required this.placeholder,
    required this.emptyText,
  });

  final List<CommandGroup> groups;
  final String placeholder;
  final String emptyText;

  @override
  State<_CommandBody> createState() => _CommandBodyState();
}

class _CommandBodyState extends State<_CommandBody> {
  final _controller = TextEditingController();
  String _query = '';
  int _highlightedIndex = 0;
  late List<_FlatItem> _allItems;
  late List<_FlatItem> _filtered;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _allItems = _flattenGroups(widget.groups);
    _filtered = _allItems;
    _focusNode.requestFocus();
  }

  List<_FlatItem> _flattenGroups(List<CommandGroup> groups) {
    final items = <_FlatItem>[];
    for (final group in groups) {
      for (final item in group.items) {
        items.add(_FlatItem(group: group.heading, item: item));
      }
    }
    return items;
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      if (_query.isEmpty) {
        _filtered = _allItems;
      } else {
        final q = _query.toLowerCase();
        _filtered = _allItems.where((fi) {
          return fi.item.label.toLowerCase().contains(q) ||
              fi.item.keywords.any((k) => k.toLowerCase().contains(q));
        }).toList();
      }
      _highlightedIndex = 0;
    });
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1) % _filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex =
            (_highlightedIndex - 1 + _filtered.length) % _filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filtered.isNotEmpty) {
        final item = _filtered[_highlightedIndex].item;
        Navigator.of(context).pop();
        item.onSelect?.call();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group filtered items by heading.
    final groupedItems = <String?, List<_FlatItem>>{};
    for (final fi in _filtered) {
      groupedItems.putIfAbsent(fi.group, () => []).add(fi);
    }

    int runningIndex = 0;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.foreground,
                    ),
                    cursorColor: AppColors.foreground,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          // Results
          if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacing.xxl),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in groupedItems.entries) ...[
                      if (entry.key != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
                          child: Text(
                            entry.key!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      for (final fi in entry.value) ...[
                        _CommandItemWidget(
                          item: fi.item,
                          isHighlighted: runningIndex == _highlightedIndex,
                          onTap: () {
                            Navigator.of(context).pop();
                            fi.item.onSelect?.call();
                          },
                        ),
                        // Increment running index inline — use a Builder.
                        Builder(builder: (_) {
                          runningIndex++;
                          return const SizedBox.shrink();
                        }),
                      ],
                      // Separator between groups
                      if (entry.key != groupedItems.keys.last)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                          child: Container(height: 1, color: AppColors.border),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlatItem {
  const _FlatItem({required this.group, required this.item});

  final String? group;
  final CommandItem item;
}

class _CommandItemWidget extends StatefulWidget {
  const _CommandItemWidget({
    required this.item,
    required this.isHighlighted,
    required this.onTap,
  });

  final CommandItem item;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  State<_CommandItemWidget> createState() => _CommandItemWidgetState();
}

class _CommandItemWidgetState extends State<_CommandItemWidget> {
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
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
          color: (widget.isHighlighted || _hovered)
              ? AppColors.surfaceHover
              : Colors.transparent,
          child: Row(
            children: [
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
              if (widget.item.shortcut != null)
                Text(
                  widget.item.shortcut!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    fontFamily: AppFonts.mono,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
