import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A carousel/slider component inspired by shadcn/ui Carousel.
///
/// ```dart
/// Carousel(
///   children: [
///     Container(color: Colors.red),
///     Container(color: Colors.green),
///     Container(color: Colors.blue),
///   ],
/// )
/// ```
class Carousel extends StatefulWidget {
  const Carousel({
    super.key,
    required this.children,
    this.height = 200,
    this.autoplay = false,
    this.autoplayInterval = const Duration(seconds: 5),
    this.loop = false,
    this.showControls = true,
    this.showIndicators = true,
    this.orientation = Axis.horizontal,
    this.viewportFraction = 1.0,
  });

  /// Slides to display.
  final List<Widget> children;

  /// Carousel height.
  final double height;

  /// Whether to autoplay.
  final bool autoplay;

  /// Interval between auto-advances.
  final Duration autoplayInterval;

  /// Whether to loop.
  final bool loop;

  /// Whether to show prev/next controls.
  final bool showControls;

  /// Whether to show dot indicators.
  final bool showIndicators;

  /// Scroll orientation.
  final Axis orientation;

  /// Fraction of the viewport each page occupies.
  final double viewportFraction;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
    if (widget.autoplay) _startAutoplay();
  }

  void _startAutoplay() {
    Future.delayed(widget.autoplayInterval, () {
      if (!mounted) return;
      _next();
      if (widget.autoplay) _startAutoplay();
    });
  }

  void _prev() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.loop) {
      _controller.animateToPage(
        widget.children.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (_currentPage < widget.children.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.loop) {
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: widget.orientation,
                itemCount: widget.children.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.xs),
                  child: widget.children[index],
                ),
              ),
              if (widget.showControls) ...[
                Positioned(
                  left: Spacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselButton(
                      icon: LucideIcons.chevron_left,
                      onTap: _prev,
                    ),
                  ),
                ),
                Positioned(
                  right: Spacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselButton(
                      icon: LucideIcons.chevron_right,
                      onTap: _next,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.showIndicators && widget.children.length > 1) ...[
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.children.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      width: i == _currentPage ? Spacing.lg : Spacing.sm,
                      height: Spacing.sm,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? AppColors.primary
                            : AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CarouselButton extends StatefulWidget {
  const _CarouselButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CarouselButton> createState() => _CarouselButtonState();
}

class _CarouselButtonState extends State<_CarouselButton> {
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceHover
                : AppColors.card.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
