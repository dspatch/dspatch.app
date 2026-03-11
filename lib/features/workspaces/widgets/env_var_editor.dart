// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Key-value pair editor for agent environment variables.
///
/// Similar to [RequiredEnvEditor] but manages both keys and values.
/// Shows required-key indicators and a hint about `{{apikey:KeyName}}` syntax.
class EnvVarEditor extends StatefulWidget {
  const EnvVarEditor({
    super.key,
    required this.env,
    this.requiredKeys = const [],
    required this.onChanged,
    this.addButtonLabel = 'Add Variable',
    this.hintText = 'Use {{apikey:Name}} to inject API keys',
  });

  /// Current environment variables (key → value).
  final Map<String, String> env;

  /// Keys that the agent's template declares as required.
  final List<String> requiredKeys;

  /// Called when the env map changes.
  final ValueChanged<Map<String, String>> onChanged;

  /// Label for the add button.
  final String addButtonLabel;

  /// Hint text shown next to the add button.
  final String hintText;

  @override
  State<EnvVarEditor> createState() => _EnvVarEditorState();
}

class _EnvVarEditorState extends State<EnvVarEditor> {
  late List<MapEntry<String, String>> _entries;
  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    _entries = widget.env.entries.toList();
    _syncControllers();
  }

  @override
  void didUpdateWidget(EnvVarEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.env != widget.env) {
      _entries = widget.env.entries.toList();
      _syncControllers();
    }
  }

  void _syncControllers() {
    // Trim excess controllers.
    while (_keyControllers.length > _entries.length) {
      _keyControllers.removeLast().dispose();
      _valueControllers.removeLast().dispose();
    }
    // Update existing controllers (defer .text to avoid platform channel error).
    for (var i = 0; i < _keyControllers.length; i++) {
      final entry = _entries[i];
      final keyCtl = _keyControllers[i];
      final valCtl = _valueControllers[i];
      if (keyCtl.text != entry.key || valCtl.text != entry.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (keyCtl.text != entry.key) keyCtl.text = entry.key;
          if (valCtl.text != entry.value) valCtl.text = entry.value;
        });
      }
    }
    // Add new controllers.
    for (var i = _keyControllers.length; i < _entries.length; i++) {
      _keyControllers.add(TextEditingController(text: _entries[i].key));
      _valueControllers.add(TextEditingController(text: _entries[i].value));
    }
  }

  @override
  void dispose() {
    for (final c in _keyControllers) {
      c.dispose();
    }
    for (final c in _valueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(Map.fromEntries(_entries));
  }

  void _add() {
    setState(() {
      _entries.add(const MapEntry('', ''));
      _keyControllers.add(TextEditingController());
      _valueControllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _entries.removeAt(index);
      _keyControllers.removeAt(index).dispose();
      _valueControllers.removeAt(index).dispose();
    });
    _notify();
  }

  void _updateKey(int index, String key) {
    setState(() => _entries[index] = MapEntry(key, _entries[index].value));
    _notify();
  }

  void _updateValue(int index, String value) {
    setState(() => _entries[index] = MapEntry(_entries[index].key, value));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _entries.length; i++) _buildRow(i),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Button(
              label: widget.addButtonLabel,
              icon: LucideIcons.plus,
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              onPressed: _add,
            ),
            const Spacer(),
            Text(
              widget.hintText,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final key = _entries[index].key;
    final isRequired = widget.requiredKeys.contains(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Field(
              label: 'Key',
              child: Input(
                controller: _keyControllers[index],
                placeholder: 'ENV_KEY',
                onChanged: (val) => _updateKey(index, val),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            flex: 3,
            child: Field(
              label: 'Value',
              child: Input(
                controller: _valueControllers[index],
                placeholder: 'value or {{apikey:Name}}',
                onChanged: (val) => _updateValue(index, val),
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          SizedBox(
            width: 44,
            child: isRequired
                ? const Center(
                    child: DspatchBadge(
                      label: 'req',
                      variant: BadgeVariant.secondary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
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
