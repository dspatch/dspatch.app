import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Provides label and error state from a [Field] to descendant input widgets.
///
/// Input widgets (e.g. [Input]) read this via [FieldScope.maybeOf] to render
/// the label natively inside their [InputDecoration], letting the
/// [OutlineInputBorder] handle the notch, hover, and focus states correctly.
class FieldScope extends InheritedWidget {
  const FieldScope({
    super.key,
    required this.label,
    required this.hasError,
    required super.child,
  });

  /// Pre-styled label widget to display on the input border.
  final Widget label;

  /// Whether the owning [Field] is in an error state.
  final bool hasError;

  static FieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FieldScope>();

  @override
  bool updateShouldNotify(FieldScope oldWidget) =>
      label != oldWidget.label || hasError != oldWidget.hasError;
}

/// Controls how the [Field] label is positioned relative to the input.
enum FieldVariant {
  /// Label appears on the border line of the child widget (default).
  inset,

  /// Label appears above the child widget.
  stacked,
}

/// A form field wrapper inspired by shadcn/ui Field.
///
/// Composes a label, input, description, and error message.
///
/// By default the label is rendered **on the border** of the child widget
/// ([FieldVariant.inset]). The child [Input] picks up the label via
/// [FieldScope] and renders it natively through [InputDecoration.label],
/// so hover, focus, and error states are handled by Flutter's
/// [OutlineInputBorder] notch — no opaque overlays.
///
/// Use [FieldVariant.stacked] for the classic label-above-input layout.
///
/// ```dart
/// Field(
///   label: 'Email',
///   required: true,
///   description: 'We will never share your email.',
///   error: _emailError,
///   child: Input(
///     placeholder: 'you@example.com',
///     onChanged: (v) {},
///   ),
/// )
/// ```
class Field extends StatelessWidget {
  const Field({
    super.key,
    this.label,
    this.required = false,
    this.description,
    this.error,
    this.variant = FieldVariant.inset,
    required this.child,
  });

  /// Label text shown above or on the border of the input.
  final String? label;

  /// Whether to show a required asterisk on the label.
  final bool required;

  /// Helper description shown below the input.
  final String? description;

  /// Error message. When non-null, displayed in destructive color.
  final String? error;

  /// How the label is positioned relative to the input.
  final FieldVariant variant;

  /// The input widget (typically [Input]).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    Widget inputChild;
    if (variant == FieldVariant.inset && label != null) {
      inputChild = FieldScope(
        label: _buildInsetLabel(),
        hasError: hasError,
        child: child,
      );
    } else {
      inputChild = child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (variant == FieldVariant.stacked && label != null) ...[
          _buildStackedLabel(),
          const SizedBox(height: Spacing.xs),
        ],
        inputChild,
        if (description != null && !hasError) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            description!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStackedLabel() {
    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.sans,
          color: error != null
              ? AppColors.destructive
              : AppColors.foreground,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.destructive),
            ),
        ],
      ),
    );
  }

  Widget _buildInsetLabel() {
    final color =
        error != null ? AppColors.destructive : AppColors.mutedForeground;
    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 14,
          fontFamily: AppFonts.mono,
          color: color,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.destructive),
            ),
        ],
      ),
    );
  }
}
