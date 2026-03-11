import 'package:flutter/material.dart';

/// A thin wrapper around Flutter's [Directionality], inspired by shadcn/ui Direction.
///
/// ```dart
/// Direction(
///   textDirection: TextDirection.rtl,
///   child: Text('مرحبا'),
/// )
/// ```
class Direction extends StatelessWidget {
  const Direction({
    super.key,
    required this.textDirection,
    required this.child,
  });

  /// The text direction to apply.
  final TextDirection textDirection;

  /// Child widget tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: child,
    );
  }
}
