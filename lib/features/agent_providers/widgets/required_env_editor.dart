// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Editor for a list of required environment variable key names.
///
/// Simplified version of [EnvVarEditor] that only manages key names
/// (no values, no secret toggle, no enabled toggle). Keys are validated
/// at form save time, not inline.
class RequiredEnvEditor extends StatefulWidget {
  final List<String> keys;
  final ValueChanged<List<String>> onChanged;

  const RequiredEnvEditor({
    super.key,
    required this.keys,
    required this.onChanged,
  });

  @override
  State<RequiredEnvEditor> createState() => _RequiredEnvEditorState();
}

class _RequiredEnvEditorState extends State<RequiredEnvEditor> {
  late List<String> _keys;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _keys = List.of(widget.keys);
    _syncControllers();
  }

  @override
  void didUpdateWidget(RequiredEnvEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keys != widget.keys) {
      _keys = List.of(widget.keys);
      _syncControllers();
    }
  }

  void _syncControllers() {
    while (_controllers.length > _keys.length) {
      _controllers.removeLast().dispose();
    }
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text != _keys[i]) {
        _controllers[i].text = _keys[i];
      }
    }
    for (var i = _controllers.length; i < _keys.length; i++) {
      _controllers.add(TextEditingController(text: _keys[i]));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(List.of(_keys));

  void _add() {
    setState(() {
      _keys.add('');
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _keys.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
    _notify();
  }

  void _update(int index, String value) {
    setState(() => _keys[index] = value);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _keys.length; i++) _buildRow(i),
        const SizedBox(height: Spacing.sm),
        Button(
          label: 'Add Key',
          icon: LucideIcons.plus,
          variant: ButtonVariant.outline,
          onPressed: _add,
        ),
      ],
    );
  }

  Widget _buildRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Field(
              label: 'Key Name',
              child: Input(
                controller: _controllers[index],
                placeholder: 'ENV_VAR_NAME',
                onChanged: (val) => _update(index, val),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          DspatchIconButton(
            icon: LucideIcons.x,
            variant: IconButtonVariant.ghost,
            size: IconButtonSize.md,
            tooltip: 'Remove',
            onPressed: () => _remove(index),
          ),
        ],
      ),
    );
  }
}
