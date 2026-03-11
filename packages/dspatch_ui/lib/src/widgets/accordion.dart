import 'package:flutter/material.dart';import 'package:flutter_lucide/flutter_lucide.dart';


import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Accordion type controlling how many items can be open.
enum AccordionType { single, multiple }

/// An expandable accordion inspired by shadcn/ui Accordion.
///
/// ```dart
/// Accordion(
///   type: AccordionType.single,
///   children: [
///     AccordionItem(
///       value: 'item-1',
///       title: 'Is it accessible?',
///       content: Text('Yes. It adheres to the WAI-ARIA design pattern.'),
///     ),flutter_lucidedflutter_lucidecide.dart
///     AccordionItem(
///       value: 'item-2',
///       title: 'Is it styled?',
///       content: Text('Yes. It ships with default styles.'),
///     ),
///   ],
/// )
/// ```
class Accordion extends StatefulWidget {
  const Accordion({
    super.key,
    required this.children,
    this.type = AccordionType.single,
    this.defaultValue,
  });

  /// Accordion items.
  final List<AccordionItem> children;

  /// Single or multiple expansion.
  final AccordionType type;

  /// Initially expanded value(s). For single type, provide one value.
  final Set<String>? defaultValue;

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  late Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultValue != null
        ? Set.from(widget.defaultValue!)
        : {};
  }

  void _toggle(String value) {
    setState(() {
      if (_expanded.contains(value)) {
        _expanded.remove(value);
      } else {
        if (widget.type == AccordionType.single) {
          _expanded.clear();
        }
        _expanded.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          _AccordionItemWidget(
            item: widget.children[i],
            isExpanded: _expanded.contains(widget.children[i].value),
            onToggle: () => _toggle(widget.children[i].value),
            isLast: i == widget.children.length - 1,
          ),
      ],
    );
  }
}

/// Configuration for a single accordion item.
class AccordionItem extends StatelessWidget {
  const AccordionItem({
    super.key,
    required this.value,
    required this.title,
    required this.content,
  });

  /// Unique value.
  final String value;

  /// Trigger title text.
  final String title;

  /// Expanded content.
  final Widget content;

  @override
  Widget build(BuildContext context) {
    // Rendered by Accordion, not directly.
    return const SizedBox.shrink();
  }
}

class _AccordionItemWidget extends StatefulWidget {
  const _AccordionItemWidget({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.isLast,
  });

  final AccordionItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isLast;

  @override
  State<_AccordionItemWidget> createState() => _AccordionItemWidgetState();
}

class _AccordionItemWidgetState extends State<_AccordionItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AccordionItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trigger
        GestureDetector(
          onTap: widget.onToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: widget.isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: const Icon(
                      LucideIcons.chevron_down,
                      size: 18,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Spacing.lg),
            child: widget.item.content,
          ),
        ),
      ],
    );
  }
}
