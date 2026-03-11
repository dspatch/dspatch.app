import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'field.dart';

/// A styled text input inspired by shadcn/ui Input.
///
/// When placed inside a [Field] with [FieldVariant.inset], the label is
/// rendered natively via [InputDecoration.label] so the [OutlineInputBorder]
/// handles the notch, hover, and focus states correctly.
///
/// ```dart
/// Input(
///   placeholder: 'Enter your email',
///   onChanged: (value) => print(value),
/// )
/// ```
class Input extends StatelessWidget {
  const Input({
    super.key,
    this.controller,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.initialValue,
    this.borderRadius,
    this.border,
    this.focusedBorder,
    this.disabledBorder,
  });

  /// Text editing controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? placeholder;

  /// Whether the input is disabled.
  final bool disabled;

  /// Whether the input is read-only (focusable but not editable).
  final bool readOnly;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (e.g. presses enter).
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type hint.
  final TextInputType? keyboardType;

  /// Whether to auto-focus on mount.
  final bool autofocus;

  /// Maximum number of lines.
  final int maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Focus node for manual focus control.
  final FocusNode? focusNode;

  /// Widget displayed before the input text.
  final Widget? prefix;

  /// Widget displayed after the input text.
  final Widget? suffix;

  /// Initial value to pre-populate the field (used when no [controller]).
  final String? initialValue;

  /// Optional border radius override (used when [border] is not set).
  final BorderRadius? borderRadius;

  /// Custom border for the enabled/base state. Overrides the default
  /// [OutlineInputBorder]. When set, [borderRadius] is ignored.
  /// [focusedBorder] and [disabledBorder] fall back to this if not set.
  final InputBorder? border;

  /// Custom border for the focused state. Falls back to [border].
  final InputBorder? focusedBorder;

  /// Custom border for the disabled state. Falls back to [border].
  final InputBorder? disabledBorder;

  @override
  Widget build(BuildContext context) {
    final scope = FieldScope.maybeOf(context);
    final hasFieldError = scope?.hasError ?? false;

    final effectiveController = controller ??
        (initialValue != null
            ? (TextEditingController(text: initialValue))
            : null);

    final defaultRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    final baseBorderSide = hasFieldError
        ? const BorderSide(color: AppColors.destructive, width: 1)
        : const BorderSide(color: AppColors.input, width: 1);
    final focusBorderSide = hasFieldError
        ? const BorderSide(color: AppColors.destructive, width: 1)
        : const BorderSide(color: AppColors.ring, width: 1);
    final disabledBorderSide = BorderSide(
      color: (hasFieldError ? AppColors.destructive : AppColors.input)
          .withValues(alpha: 0.5),
      width: 1,
    );

    return TextField(
      controller: effectiveController,
      enabled: !disabled,
      readOnly: readOnly,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      focusNode: focusNode,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.foreground,
      ),
      cursorColor: AppColors.foreground,
      decoration: InputDecoration(
        label: scope?.label,
        floatingLabelBehavior: scope != null
            ? FloatingLabelBehavior.always
            : null,
        hintText: placeholder,
        hintStyle: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 13,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.all(Spacing.md),
        border: border ?? OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: baseBorderSide,
        ),
        enabledBorder: border ?? OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: baseBorderSide,
        ),
        focusedBorder: focusedBorder ?? border ?? OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: focusBorderSide,
        ),
        disabledBorder: disabledBorder ?? border ?? OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: disabledBorderSide,
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
    );
  }
}
