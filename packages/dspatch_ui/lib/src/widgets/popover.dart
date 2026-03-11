import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Side from which the popover appears.
enum PopoverSide { top, bottom, left, right }

/// Alignment within the popover side.
enum PopoverAlign { start, center, end }

/// A popover overlay inspired by shadcn/ui Popover.
///
/// ```dart
/// Popover(
///   trigger: Button(label: 'Open', onPressed: null),
///   content: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Popover content'),
///   ),
/// )
/// ```
class Popover extends StatefulWidget {
  const Popover({
    super.key,
    required this.trigger,
    required this.content,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.center,
    this.offset = Spacing.xs,
  });

  /// Widget that triggers the popover on tap.
  final Widget trigger;

  /// Popover content.
  final Widget content;

  /// Side from which the popover appears.
  final PopoverSide side;

  /// Alignment along the side axis.
  final PopoverAlign align;

  /// Offset from the trigger.
  final double offset;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isOpen = false;

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
    setState(() => _isOpen = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    setState(() => _isOpen = false);
  }

  Offset _getOffset() {
    return switch (widget.side) {
      PopoverSide.bottom => Offset(0, widget.offset),
      PopoverSide.top => Offset(0, -widget.offset),
      PopoverSide.right => Offset(widget.offset, 0),
      PopoverSide.left => Offset(-widget.offset, 0),
    };
  }

  Alignment _getTargetAnchor() {
    return switch (widget.side) {
      PopoverSide.bottom => switch (widget.align) {
          PopoverAlign.start => Alignment.bottomLeft,
          PopoverAlign.center => Alignment.bottomCenter,
          PopoverAlign.end => Alignment.bottomRight,
        },
      PopoverSide.top => switch (widget.align) {
          PopoverAlign.start => Alignment.topLeft,
          PopoverAlign.center => Alignment.topCenter,
          PopoverAlign.end => Alignment.topRight,
        },
      PopoverSide.right => switch (widget.align) {
          PopoverAlign.start => Alignment.topRight,
          PopoverAlign.center => Alignment.centerRight,
          PopoverAlign.end => Alignment.bottomRight,
        },
      PopoverSide.left => switch (widget.align) {
          PopoverAlign.start => Alignment.topLeft,
          PopoverAlign.center => Alignment.centerLeft,
          PopoverAlign.end => Alignment.bottomLeft,
        },
    };
  }

  Alignment _getFollowerAnchor() {
    return switch (widget.side) {
      PopoverSide.bottom => switch (widget.align) {
          PopoverAlign.start => Alignment.topLeft,
          PopoverAlign.center => Alignment.topCenter,
          PopoverAlign.end => Alignment.topRight,
        },
      PopoverSide.top => switch (widget.align) {
          PopoverAlign.start => Alignment.bottomLeft,
          PopoverAlign.center => Alignment.bottomCenter,
          PopoverAlign.end => Alignment.bottomRight,
        },
      PopoverSide.right => switch (widget.align) {
          PopoverAlign.start => Alignment.topLeft,
          PopoverAlign.center => Alignment.centerLeft,
          PopoverAlign.end => Alignment.bottomLeft,
        },
      PopoverSide.left => switch (widget.align) {
          PopoverAlign.start => Alignment.topRight,
          PopoverAlign.center => Alignment.centerRight,
          PopoverAlign.end => Alignment.bottomRight,
        },
    };
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        // Dismiss on tap outside.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: _getTargetAnchor(),
          followerAnchor: _getFollowerAnchor(),
          offset: _getOffset(),
          child: Material(
            color: AppColors.popover,
            borderRadius: BorderRadius.circular(AppRadius.md),
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: widget.content,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: widget.trigger,
      ),
    );
  }
}
