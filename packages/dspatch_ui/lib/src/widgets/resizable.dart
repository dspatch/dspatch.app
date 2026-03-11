import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Configuration for a single resizable panel.
class ResizablePanel {
  const ResizablePanel({
    required this.child,
    this.initialFlex = 1,
    this.minFlex = 0.1,
  });

  /// Panel content.
  final Widget child;

  /// Initial flex weight (relative size).
  final double initialFlex;

  /// Minimum flex weight.
  final double minFlex;
}

/// A split-pane container with draggable handles, inspired by shadcn/ui Resizable.
///
/// ```dart
/// Resizable(
///   children: [
///     ResizablePanel(child: Text('Left'), initialFlex: 1),
///     ResizablePanel(child: Text('Right'), initialFlex: 2),
///   ],
/// )
/// ```
class Resizable extends StatefulWidget {
  const Resizable({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.handleSize = 8,
  });

  /// Panels to display.
  final List<ResizablePanel> children;

  /// Layout direction.
  final Axis direction;

  /// Width/height of the drag handle area.
  final double handleSize;

  @override
  State<Resizable> createState() => _ResizableState();
}

class _ResizableState extends State<Resizable> {
  late List<double> _flexValues;

  @override
  void initState() {
    super.initState();
    _flexValues =
        widget.children.map((p) => p.initialFlex).toList();
  }

  void _onDrag(int handleIndex, double delta) {
    setState(() {
      final total = _flexValues[handleIndex] + _flexValues[handleIndex + 1];
      final newLeft = (_flexValues[handleIndex] + delta)
          .clamp(widget.children[handleIndex].minFlex, total - widget.children[handleIndex + 1].minFlex);
      _flexValues[handleIndex] = newLeft;
      _flexValues[handleIndex + 1] = total - newLeft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.direction == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final totalHandleSpace =
            widget.handleSize * (widget.children.length - 1);
        final availableSize = totalSize - totalHandleSpace;
        final flexSum = _flexValues.fold<double>(0, (a, b) => a + b);

        final items = <Widget>[];
        for (int i = 0; i < widget.children.length; i++) {
          final panelSize = availableSize * (_flexValues[i] / flexSum);
          items.add(
            SizedBox(
              width: widget.direction == Axis.horizontal ? panelSize : null,
              height: widget.direction == Axis.vertical ? panelSize : null,
              child: widget.children[i].child,
            ),
          );

          if (i < widget.children.length - 1) {
            items.add(_ResizableHandle(
              direction: widget.direction,
              size: widget.handleSize,
              onDrag: (delta) {
                final normalized = delta / availableSize * flexSum;
                _onDrag(i, normalized);
              },
            ));
          }
        }

        return widget.direction == Axis.horizontal
            ? Row(children: items)
            : Column(children: items);
      },
    );
  }
}

class _ResizableHandle extends StatefulWidget {
  const _ResizableHandle({
    required this.direction,
    required this.size,
    required this.onDrag,
  });

  final Axis direction;
  final double size;
  final ValueChanged<double> onDrag;

  @override
  State<_ResizableHandle> createState() => _ResizableHandleState();
}

class _ResizableHandleState extends State<_ResizableHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.direction == Axis.horizontal;

    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: isHorizontal
            ? (d) => widget.onDrag(d.delta.dx)
            : null,
        onVerticalDragUpdate: !isHorizontal
            ? (d) => widget.onDrag(d.delta.dy)
            : null,
        child: Container(
          width: isHorizontal ? widget.size : double.infinity,
          height: !isHorizontal ? widget.size : double.infinity,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: isHorizontal ? 3 : Spacing.xxl,
              height: isHorizontal ? Spacing.xxl : 3,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.ring
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
