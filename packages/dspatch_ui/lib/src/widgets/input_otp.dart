import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A one-time-password input with separate digit slots, inspired by shadcn/ui InputOTP.
///
/// ```dart
/// InputOTP(
///   length: 6,
///   onCompleted: (code) => print('Code: $code'),
/// )
/// ```
class InputOTP extends StatefulWidget {
  const InputOTP({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
  });

  /// Number of digit slots.
  final int length;

  /// Called when all slots are filled.
  final ValueChanged<String>? onCompleted;

  /// Called whenever the combined value changes.
  final ValueChanged<String>? onChanged;

  @override
  State<InputOTP> createState() => _InputOTPState();
}

class _InputOTPState extends State<InputOTP> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(
      widget.length,
      (i) => FocusNode(
        onKeyEvent: (node, event) => _handleKeyEvent(i, event),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _notifyChanged() {
    widget.onChanged?.call(_value);
    if (_value.length == widget.length) {
      widget.onCompleted?.call(_value);
    }
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Handle paste (Ctrl+V / Cmd+V).
    if (key == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _handlePaste();
      return KeyEventResult.handled;
    }

    // Handle digit keys — replace current cell and advance.
    final char = event.character;
    if (char != null && char.length == 1 && RegExp(r'[0-9]').hasMatch(char)) {
      _controllers[index].text = char;
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
      _notifyChanged();
      return KeyEventResult.handled;
    }

    // Handle backspace — clear current cell, or move back if already empty.
    if (key == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
      } else if (index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
      _notifyChanged();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final digits = data!.text!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != widget.length) return;
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.length, (i) {
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? Spacing.sm : 0),
          child: SizedBox(
            width: 40,
            height: 44,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              maxLength: 1,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.mono,
                color: AppColors.foreground,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      const BorderSide(color: AppColors.input, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      const BorderSide(color: AppColors.input, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      const BorderSide(color: AppColors.ring, width: 1),
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        );
      }),
    );
  }
}
