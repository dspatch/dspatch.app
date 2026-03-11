import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import 'tooltip.dart';

/// A button that copies text to the clipboard and shows a checkmark confirmation.
///
/// ```dart
/// CopyButton(textToCopy: 'some text')
/// CopyButton(textToCopy: secret, iconSize: 16, color: AppColors.foreground)
/// ```
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.textToCopy,
    this.icon = LucideIcons.copy,
    this.copiedIcon = LucideIcons.check,
    this.iconSize = 14,
    this.color,
    this.copiedColor,
    this.copiedTooltip = 'Copied!',
    this.resetDuration = const Duration(seconds: 2),
    this.onCopied,
    this.showTooltip = true,
  });

  /// The text to copy to the clipboard on tap.
  final String textToCopy;

  /// Icon shown in the default state.
  final IconData icon;

  /// Icon shown after copying.
  final IconData copiedIcon;

  /// Size of the icon.
  final double iconSize;

  /// Icon color in default state. Defaults to [AppColors.mutedForeground].
  final Color? color;

  /// Icon color after copying. Defaults to [AppColors.success].
  final Color? copiedColor;

  /// Tooltip text shown briefly after copying.
  final String copiedTooltip;

  /// How long the checkmark stays before reverting.
  final Duration resetDuration;

  /// Optional callback fired after the text is copied.
  final VoidCallback? onCopied;

  /// Whether to show the "Copied!" tooltip. Defaults to true.
  final bool showTooltip;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    if (!mounted) return;
    setState(() => _copied = true);
    widget.onCopied?.call();
    _timer?.cancel();
    _timer = Timer(widget.resetDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.color ?? AppColors.mutedForeground;
    final successColor = widget.copiedColor ?? AppColors.success;

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleCopy,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _copied ? widget.copiedIcon : widget.icon,
            key: ValueKey(_copied),
            size: widget.iconSize,
            color: _copied ? successColor : defaultColor,
          ),
        ),
      ),
    );

    if (_copied && widget.showTooltip) {
      button = DspatchTooltip(
        message: widget.copiedTooltip,
        child: button,
      );
    }

    return button;
  }
}
