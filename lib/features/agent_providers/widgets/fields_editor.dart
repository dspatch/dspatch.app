// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:convert';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// Well-known field keys with special SDK support.
const _wellKnownFields = ['system_prompt', 'authority'];

/// Editor for template fields (key → base64-encoded value pairs).
///
/// Values are stored as base64-encoded UTF-8 strings internally, but displayed
/// and edited as plaintext. The editor handles encoding/decoding transparently.
class FieldsEditor extends StatefulWidget {
  final Map<String, String> fields;
  final ValueChanged<Map<String, String>> onChanged;

  const FieldsEditor({
    super.key,
    required this.fields,
    required this.onChanged,
  });

  @override
  State<FieldsEditor> createState() => _FieldsEditorState();
}

class _FieldsEditorState extends State<FieldsEditor> {
  late Map<String, String> _fields; // key → base64 value
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, TextEditingController> _valueControllers = {};
  late List<String> _orderedKeys;

  @override
  void initState() {
    super.initState();
    _fields = Map.of(widget.fields);
    _orderedKeys = _fields.keys.toList();
    _syncControllers();
  }

  @override
  void didUpdateWidget(FieldsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _fields = Map.of(widget.fields);
      _orderedKeys = _fields.keys.toList();
      _syncControllers();
    }
  }

  void _syncControllers() {
    // Remove controllers for keys no longer present.
    final keysToRemove = _keyControllers.keys
        .where((k) => !_orderedKeys.contains(k))
        .toList();
    for (final k in keysToRemove) {
      _keyControllers.remove(k)?.dispose();
      _valueControllers.remove(k)?.dispose();
    }

    // Add/update controllers for current keys.
    for (final key in _orderedKeys) {
      final decodedValue = _decodeBase64(_fields[key] ?? '');

      if (!_keyControllers.containsKey(key)) {
        _keyControllers[key] = TextEditingController(text: key);
      } else if (_keyControllers[key]!.text != key) {
        _keyControllers[key]!.text = key;
      }

      if (!_valueControllers.containsKey(key)) {
        _valueControllers[key] = TextEditingController(text: decodedValue);
      } else if (_valueControllers[key]!.text != decodedValue) {
        _valueControllers[key]!.text = decodedValue;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _decodeBase64(String encoded) {
    if (encoded.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      // If not valid base64, return raw value for editing.
      return encoded;
    }
  }

  String _encodeBase64(String plaintext) {
    if (plaintext.isEmpty) return '';
    return base64Encode(utf8.encode(plaintext));
  }

  void _notify() => widget.onChanged(Map.of(_fields));

  void _add() {
    // Pick the first well-known field not yet used, or empty string.
    final usedKeys = _fields.keys.toSet();
    final suggestion =
        _wellKnownFields.where((k) => !usedKeys.contains(k)).firstOrNull ?? '';

    final newKey = suggestion.isEmpty ? 'field_${_fields.length}' : suggestion;
    setState(() {
      _fields[newKey] = '';
      _orderedKeys.add(newKey);
      _keyControllers[newKey] = TextEditingController(text: newKey);
      _valueControllers[newKey] = TextEditingController();
    });
    _notify();
  }

  void _remove(String key) {
    setState(() {
      _fields.remove(key);
      _orderedKeys.remove(key);
      _keyControllers.remove(key)?.dispose();
      _valueControllers.remove(key)?.dispose();
    });
    _notify();
  }

  void _updateKey(String oldKey, String newKey) {
    if (oldKey == newKey) return;
    // Prevent duplicate keys.
    if (_fields.containsKey(newKey)) return;

    setState(() {
      final value = _fields.remove(oldKey) ?? '';
      _fields[newKey] = value;

      final idx = _orderedKeys.indexOf(oldKey);
      if (idx != -1) _orderedKeys[idx] = newKey;

      // Move controllers to new key.
      final keyCtrl = _keyControllers.remove(oldKey);
      final valCtrl = _valueControllers.remove(oldKey);
      if (keyCtrl != null) _keyControllers[newKey] = keyCtrl;
      if (valCtrl != null) _valueControllers[newKey] = valCtrl;
    });
    _notify();
  }

  void _updateValue(String key, String plaintext) {
    setState(() => _fields[key] = _encodeBase64(plaintext));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in _orderedKeys) _buildRow(key),
        const SizedBox(height: Spacing.sm),
        Button(
          label: 'Add Field',
          icon: LucideIcons.plus,
          variant: ButtonVariant.outline,
          onPressed: _add,
        ),
      ],
    );
  }

  Widget _buildRow(String key) {
    final isWellKnown = _wellKnownFields.contains(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Field(
                        label: 'Field Key',
                        child: Input(
                          controller: _keyControllers[key],
                          placeholder: 'field_name',
                          onChanged: (val) => _updateKey(key, val),
                        ),
                      ),
                    ),
                    if (isWellKnown) ...[
                      const SizedBox(width: Spacing.sm),
                      const Padding(
                        padding: EdgeInsets.only(top: 22),
                        child: DspatchBadge(
                          label: 'SDK',
                          variant: BadgeVariant.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Field(
                  label: 'Value',
                  child: Input(
                    controller: _valueControllers[key],
                    placeholder: isWellKnown && key == 'system_prompt'
                        ? 'You are a helpful coding assistant...'
                        : isWellKnown && key == 'authority'
                            ? 'You may freely refactor code...'
                            : 'Field value...',
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (val) => _updateValue(key, val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: DspatchIconButton(
              icon: LucideIcons.x,
              variant: IconButtonVariant.ghost,
              size: IconButtonSize.md,
              tooltip: 'Remove',
              onPressed: () => _remove(key),
            ),
          ),
        ],
      ),
    );
  }
}
