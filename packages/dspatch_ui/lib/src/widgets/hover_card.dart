import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'popover.dart';

/// A card that appears on hover, inspired by shadcn/ui HoverCard.
///
/// ```dart
/// HoverCard(
///   trigger: Text('@username'),
///   content: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('User profile info here'),
///   ),
/// )
/// ```
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.trigger,
    required this.content,
    this.openDelay = const Duration(milliseconds: 200),
    this.closeDelay = const Duration(milliseconds: 100),
    this.width = 300,
    this.anchorSide = PopoverSide.bottom,
    this.anchorAlign = PopoverAlign.start,
  });

  /// Widget that triggers the hover card.
  final Widget trigger;

  /// Hover card content.
  final Widget content;

  /// Delay before opening.
  final Duration openDelay;

  /// Delay before closing.
  final Duration closeDelay;

  /// Card width.
  final double width;

  /// Side of the trigger where the card appears.
  final PopoverSide anchorSide;

  /// Alignment along the anchor side axis.
  final PopoverAlign anchorAlign;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  final _triggerKey = GlobalKey();
  OverlayEntry? _entry;
  bool _isHoveringTrigger = false;
  bool _isHoveringCard = false;

  void _scheduleOpen() {
    _isHoveringTrigger = true;
    Future.delayed(widget.openDelay, () {
      if (_isHoveringTrigger && mounted && _entry == null) {
        _open();
      }
    });
  }

  void _scheduleTriggerClose() {
    _isHoveringTrigger = false;
    Future.delayed(widget.closeDelay, () {
      if (!_isHoveringTrigger && !_isHoveringCard) {
        _close();
      }
    });
  }

  void _onCardHoverEnter() {
    _isHoveringCard = true;
  }

  void _onCardHoverExit() {
    _isHoveringCard = false;
    Future.delayed(widget.closeDelay, () {
      if (!_isHoveringTrigger && !_isHoveringCard) {
        _close();
      }
    });
  }

  void _open() {
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  /// Compute the overlay card position from the trigger's global rect.
  Offset _computePosition(Size triggerSize, Offset triggerPos) {
    double dx, dy;

    switch (widget.anchorSide) {
      case PopoverSide.bottom:
        dy = triggerPos.dy + triggerSize.height + Spacing.xs;
        dx = switch (widget.anchorAlign) {
          PopoverAlign.start => triggerPos.dx,
          PopoverAlign.center =>
            triggerPos.dx + triggerSize.width / 2 - widget.width / 2,
          PopoverAlign.end => triggerPos.dx + triggerSize.width - widget.width,
        };
      case PopoverSide.top:
        // Card above trigger — dy is computed after layout via bottom anchor.
        dy = triggerPos.dy - Spacing.xs; // adjusted in Positioned via bottom
        dx = switch (widget.anchorAlign) {
          PopoverAlign.start => triggerPos.dx,
          PopoverAlign.center =>
            triggerPos.dx + triggerSize.width / 2 - widget.width / 2,
          PopoverAlign.end => triggerPos.dx + triggerSize.width - widget.width,
        };
      case PopoverSide.left:
        dx = triggerPos.dx - widget.width - Spacing.xs;
        dy = switch (widget.anchorAlign) {
          PopoverAlign.start => triggerPos.dy,
          PopoverAlign.center => triggerPos.dy + triggerSize.height / 2,
          PopoverAlign.end => triggerPos.dy + triggerSize.height,
        };
      case PopoverSide.right:
        dx = triggerPos.dx + triggerSize.width + Spacing.xs;
        dy = switch (widget.anchorAlign) {
          PopoverAlign.start => triggerPos.dy,
          PopoverAlign.center => triggerPos.dy + triggerSize.height / 2,
          PopoverAlign.end => triggerPos.dy + triggerSize.height,
        };
    }
    return Offset(dx, dy);
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    // Convert trigger position into the overlay's local coordinate space
    // so Positioned works correctly regardless of sidebar/scaffold offsets.
    final overlayBox =
        Overlay.of(this.context).context.findRenderObject() as RenderBox;
    final triggerSize = renderBox.size;
    final triggerPos =
        overlayBox.globalToLocal(renderBox.localToGlobal(Offset.zero));
    final pos = _computePosition(triggerSize, triggerPos);

    final card = MouseRegion(
      onEnter: (_) => _onCardHoverEnter(),
      onExit: (_) => _onCardHoverExit(),
      child: Material(
        color: AppColors.popover,
        borderRadius: BorderRadius.circular(AppRadius.md),
        elevation: 4,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: widget.content,
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: card,
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
    return MouseRegion(
      key: _triggerKey,
      onEnter: (_) => _scheduleOpen(),
      onExit: (_) => _scheduleTriggerClose(),
      child: widget.trigger,
    );
  }
}
