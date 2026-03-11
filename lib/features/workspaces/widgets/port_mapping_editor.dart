// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// List editor for Docker port mappings (`"host:container"` format).
///
/// Follows the same add/remove/update pattern as [RequiredEnvEditor].
class PortMappingEditor extends StatefulWidget {
  const PortMappingEditor({
    super.key,
    required this.ports,
    required this.onChanged,
  });

  final List<String> ports;
  final ValueChanged<List<String>> onChanged;

  @override
  State<PortMappingEditor> createState() => _PortMappingEditorState();
}

class _PortMappingEditorState extends State<PortMappingEditor> {
  late List<String> _ports;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _ports = List.of(widget.ports);
    _syncControllers();
  }

  @override
  void didUpdateWidget(PortMappingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ports != widget.ports) {
      _ports = List.of(widget.ports);
      _syncControllers();
    }
  }

  void _syncControllers() {
    while (_controllers.length > _ports.length) {
      _controllers.removeLast().dispose();
    }
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text != _ports[i]) {
        _controllers[i].text = _ports[i];
      }
    }
    for (var i = _controllers.length; i < _ports.length; i++) {
      _controllers.add(TextEditingController(text: _ports[i]));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(List.of(_ports));

  void _add() {
    setState(() {
      _ports.add('');
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _ports.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
    _notify();
  }

  void _update(int index, String value) {
    setState(() => _ports[index] = value);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _ports.length; i++) _buildRow(i),
        const SizedBox(height: Spacing.sm),
        Button(
          label: 'Add Port',
          icon: LucideIcons.plus,
          variant: ButtonVariant.outline,
          size: ButtonSize.sm,
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
            child: Input(
              controller: _controllers[index],
              placeholder: '8080:80',
              onChanged: (val) => _update(index, val),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          DspatchIconButton(
            icon: LucideIcons.x,
            variant: IconButtonVariant.ghost,
            size: IconButtonSize.sm,
            tooltip: 'Remove',
            onPressed: () => _remove(index),
          ),
        ],
      ),
    );
  }
}
