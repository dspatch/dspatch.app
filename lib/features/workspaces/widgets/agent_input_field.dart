// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Professional AI agent input field with floating appearance.
///
/// Features a card-like container, multi-line text input, and a bottom
/// toolbar with keyboard hint and send button.
class AgentInputField extends StatelessWidget {
  const AgentInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.enabled = true,
    this.isSending = false,
    this.isInterruptMode = false,
    this.onInterrupt,
    this.placeholder = 'Type a message...',
    this.statusText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool enabled;
  final bool isSending;

  /// When true, the send button becomes a red interrupt/stop button.
  final bool isInterruptMode;

  /// Called when the interrupt button is pressed.
  final VoidCallback? onInterrupt;

  final String placeholder;

  /// Optional status text shown next to the send button (e.g. "Agent is working...").
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isSending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyboardListener(
                    focusNode: focusNode,
                    onKeyEvent: isActive
                        ? (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              onSubmit();
                            }
                          }
                        : null,
                    child: Input(
                      controller: controller,
                      placeholder: placeholder,
                      minLines: 1,
                      maxLines: 4,
                      disabled: !isActive,
                      border: InputBorder.none,
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.lg),
                          topRight: Radius.circular(AppRadius.lg),
                        ),
                        borderSide:
                            BorderSide(color: AppColors.ring, width: 1),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.sm,
                                vertical: Spacing.sm,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildHintOrStatus(),
                              ),
                            ),
                          ),
                          Container(width: 1, color: AppColors.border),
                          if (isInterruptMode)
                            _InterruptButton(onPressed: onInterrupt ?? () {})
                          else
                            _SendButton(
                              enabled: isActive,
                              onPressed: onSubmit,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintOrStatus() {
    if (isSending) {
      return const Text(
        'Sending\u2026',
        style: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (enabled) {
      return const Text(
        'Enter to send \u00b7 Shift+Enter for newline',
        style: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 10,
        ),
      );
    }
    return Text(
      statusText ?? 'Input disabled',
      style: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 10,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _InterruptButton extends StatefulWidget {
  const _InterruptButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_InterruptButton> createState() => _InterruptButtonState();
}

class _InterruptButtonState extends State<_InterruptButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = _hovered
        ? AppColors.destructive.withValues(alpha: 0.85)
        : AppColors.destructive;

    return DspatchTooltip(
      message: 'Interrupt agent',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 48,
            color: baseColor,
            child: const Center(
              child: Icon(
                LucideIcons.square,
                size: 16,
                color: AppColors.destructiveForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.enabled
        ? (_hovered
            ? AppColors.primary.withValues(alpha: 0.85)
            : AppColors.primary)
        : AppColors.primary.withValues(alpha: 0.3);

    return DspatchTooltip(
      message: 'Send message',
      child: MouseRegion(
        cursor:
            widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: Container(
            width: 48,
            color: baseColor,
            child: Center(
              child: Icon(
                LucideIcons.arrow_up,
                size: 18,
                color: widget.enabled
                    ? AppColors.primaryForeground
                    : AppColors.primaryForeground.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
