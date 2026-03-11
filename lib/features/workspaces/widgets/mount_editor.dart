// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/config_copy_with.dart';


/// List editor for additional bind mounts.
///
/// Each row has a host path input (with browse buttons for both directories
/// and files), container path input, read-only toggle, and remove button.
class MountEditor extends StatefulWidget {
  const MountEditor({
    super.key,
    required this.mounts,
    required this.onChanged,
  });

  final List<MountConfig> mounts;
  final ValueChanged<List<MountConfig>> onChanged;

  @override
  State<MountEditor> createState() => _MountEditorState();
}

class _MountEditorState extends State<MountEditor> {
  late List<MountConfig> _mounts;
  final List<TextEditingController> _hostControllers = [];
  final List<TextEditingController> _containerControllers = [];

  @override
  void initState() {
    super.initState();
    _mounts = List.of(widget.mounts);
    _syncControllers();
  }

  @override
  void didUpdateWidget(MountEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mounts != widget.mounts) {
      _mounts = List.of(widget.mounts);
      _syncControllers();
    }
  }

  void _syncControllers() {
    while (_hostControllers.length > _mounts.length) {
      _hostControllers.removeLast().dispose();
      _containerControllers.removeLast().dispose();
    }
    for (var i = 0; i < _hostControllers.length; i++) {
      if (_hostControllers[i].text != _mounts[i].hostPath) {
        _hostControllers[i].text = _mounts[i].hostPath;
      }
      if (_containerControllers[i].text != _mounts[i].containerPath) {
        _containerControllers[i].text = _mounts[i].containerPath;
      }
    }
    for (var i = _hostControllers.length; i < _mounts.length; i++) {
      _hostControllers.add(
          TextEditingController(text: _mounts[i].hostPath));
      _containerControllers.add(
          TextEditingController(text: _mounts[i].containerPath));
    }
  }

  @override
  void dispose() {
    for (final c in _hostControllers) {
      c.dispose();
    }
    for (final c in _containerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(List.of(_mounts));

  void _add() {
    setState(() {
      _mounts.add(const MountConfig(
        hostPath: '',
        containerPath: '',
        readOnly: true,
      ));
      _hostControllers.add(TextEditingController());
      _containerControllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _mounts.removeAt(index);
      _hostControllers.removeAt(index).dispose();
      _containerControllers.removeAt(index).dispose();
    });
    _notify();
  }

  void _update(int index, MountConfig mount) {
    setState(() => _mounts[index] = mount);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _mounts.length; i++) _buildRow(i),
        if (_mounts.isNotEmpty) const SizedBox(height: Spacing.sm),
        Button(
          label: 'Add Mount',
          icon: LucideIcons.plus,
          variant: ButtonVariant.outline,
          size: ButtonSize.sm,
          onPressed: _add,
        ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final mount = _mounts[index];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Single row on wide screens, wrap on narrow
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Field(
                    label: 'Host Path',
                    child: _hostPathInput(index, mount),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
                  child: Icon(
                    LucideIcons.arrow_right,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Field(
                    label: 'Container Path',
                    child: Input(
                      controller: _containerControllers[index],
                      placeholder: '/data/models',
                      onChanged: (val) => _update(
                        index,
                        mount.copyWith(containerPath: val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _readOnlyToggle(index, mount),
                const SizedBox(width: Spacing.xs),
                _removeButton(index),
              ],
            );
          }

          // Wrapped layout for narrow screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Field(
                label: 'Host Path',
                child: _hostPathInput(index, mount),
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Field(
                      label: 'Container Path',
                      child: Input(
                        controller: _containerControllers[index],
                        placeholder: '/data/models',
                        onChanged: (val) => _update(
                          index,
                          mount.copyWith(containerPath: val),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _readOnlyToggle(index, mount),
                  const SizedBox(width: Spacing.xs),
                  _removeButton(index),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hostPathInput(int index, MountConfig mount) {
    return Row(
      children: [
        Expanded(
          child: Input(
            controller: _hostControllers[index],
            placeholder: 'Host path (file or directory)...',
            onChanged: (val) => _update(
              index,
              mount.copyWith(hostPath: val),
            ),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        DspatchIconButton(
          icon: LucideIcons.folder,
          variant: IconButtonVariant.ghost,
          size: IconButtonSize.sm,
          tooltip: 'Browse directory',
          onPressed: () async {
            final result = await FilePicker.platform.getDirectoryPath(
              dialogTitle: 'Select Host Directory',
            );
            if (result != null) {
              _hostControllers[index].text = result;
              _update(index, mount.copyWith(hostPath: result));
            }
          },
        ),
        DspatchIconButton(
          icon: LucideIcons.file,
          variant: IconButtonVariant.ghost,
          size: IconButtonSize.sm,
          tooltip: 'Browse file',
          onPressed: () async {
            final picked = await FilePicker.platform.pickFiles(
              dialogTitle: 'Select Host File',
            );
            final result = picked?.files.singleOrNull?.path;
            if (result != null) {
              _hostControllers[index].text = result;
              _update(index, mount.copyWith(hostPath: result));
            }
          },
        ),
      ],
    );
  }

  Widget _readOnlyToggle(int index, MountConfig mount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'RO',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        DspatchSwitch(
          value: mount.readOnly,
          size: SwitchSize.sm,
          onChanged: (val) => _update(
            index,
            mount.copyWith(readOnly: val),
          ),
        ),
      ],
    );
  }

  Widget _removeButton(int index) {
    return DspatchIconButton(
      icon: LucideIcons.x,
      variant: IconButtonVariant.ghost,
      size: IconButtonSize.sm,
      tooltip: 'Remove mount',
      onPressed: () => _remove(index),
    );
  }
}
