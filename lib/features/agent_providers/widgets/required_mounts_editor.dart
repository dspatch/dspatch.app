// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Editor for a list of required mount container paths.
///
/// Each entry is a container path (e.g. `/data/models`) that the agent
/// needs mounted. At the workspace level, the user specifies which host
/// directory to map to each required path.
class RequiredMountsEditor extends StatefulWidget {
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;

  const RequiredMountsEditor({
    super.key,
    required this.paths,
    required this.onChanged,
  });

  @override
  State<RequiredMountsEditor> createState() => _RequiredMountsEditorState();
}

class _RequiredMountsEditorState extends State<RequiredMountsEditor> {
  late List<String> _paths;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _paths = List.of(widget.paths);
    _syncControllers();
  }

  @override
  void didUpdateWidget(RequiredMountsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths != widget.paths) {
      _paths = List.of(widget.paths);
      _syncControllers();
    }
  }

  void _syncControllers() {
    while (_controllers.length > _paths.length) {
      _controllers.removeLast().dispose();
    }
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text != _paths[i]) {
        _controllers[i].text = _paths[i];
      }
    }
    for (var i = _controllers.length; i < _paths.length; i++) {
      _controllers.add(TextEditingController(text: _paths[i]));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(List.of(_paths));

  void _add() {
    setState(() {
      _paths.add('');
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _paths.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
    _notify();
  }

  void _update(int index, String value) {
    setState(() => _paths[index] = value);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _paths.length; i++) _buildRow(i),
        const SizedBox(height: Spacing.sm),
        Button(
          label: 'Add Mount',
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
              label: 'Container Path',
              child: Input(
                controller: _controllers[index],
                placeholder: '/data/models',
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
