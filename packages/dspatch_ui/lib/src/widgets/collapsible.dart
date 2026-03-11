import 'package:flutter/material.dart';

/// Expand/collapse container inspired by shadcn/ui Collapsible.
///
/// ```dart
/// Collapsible(
///   child: Column(children: [
///     CollapsibleTrigger(child: Text('Toggle')),
///     CollapsibleContent(child: Text('Hidden content')),
///   ]),
/// )
/// ```
class Collapsible extends StatefulWidget {
  const Collapsible({
    super.key,
    this.defaultOpen = false,
    required this.child,
  });

  /// Whether initially expanded.
  final bool defaultOpen;

  /// Widget tree containing [CollapsibleTrigger] and [CollapsibleContent].
  final Widget child;

  /// Access the nearest collapsible scope.
  static _CollapsibleScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CollapsibleScope>()!;
  }

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.defaultOpen;
  }

  void _toggle() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    return _CollapsibleScope(
      isOpen: _isOpen,
      toggle: _toggle,
      child: widget.child,
    );
  }
}

class _CollapsibleScope extends InheritedWidget {
  const _CollapsibleScope({
    required this.isOpen,
    required this.toggle,
    required super.child,
  });

  final bool isOpen;
  final VoidCallback toggle;

  @override
  bool updateShouldNotify(_CollapsibleScope old) => isOpen != old.isOpen;
}

/// Tappable trigger that toggles the collapsible.
class CollapsibleTrigger extends StatelessWidget {
  const CollapsibleTrigger({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Collapsible.of(context).toggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
    );
  }
}

/// Content that animates open/closed with a [SizeTransition].
class CollapsibleContent extends StatefulWidget {
  const CollapsibleContent({super.key, required this.child});

  final Widget child;

  @override
  State<CollapsibleContent> createState() => _CollapsibleContentState();
}

class _CollapsibleContentState extends State<CollapsibleContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isOpen = Collapsible.of(context).isOpen;
    if (!_initialized) {
      _controller.value = isOpen ? 1.0 : 0.0;
      _initialized = true;
    } else {
      if (isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1,
      child: widget.child,
    );
  }
}
