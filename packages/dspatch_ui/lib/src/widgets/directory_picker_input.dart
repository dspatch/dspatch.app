import 'dart:io' show Platform;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'input.dart';
import 'sonner.dart';

/// The visual style of the browse button in a [PathPickerInput].
enum PathPickerButtonStyle {
  /// A full [Button] with outline variant (default).
  outline,

  /// A full [Button] with primary variant and icon size.
  primary,

  /// A compact [DspatchIconButton] with ghost variant.
  ghost,
}

/// Whether to pick a directory or file(s).
enum PathPickerMode {
  /// Pick a single directory.
  directory,

  /// Pick a single file.
  file,
}

/// A text input with an integrated system file/directory browse button.
///
/// Uses the official Flutter team `file_selector` plugin so native dialogs
/// run correctly on macOS, Windows, Linux (XDG portal), and Android. Directory
/// picking is not supported on iOS — the browse button is disabled there.
///
/// On macOS, the sandbox entitlement
/// `com.apple.security.files.user-selected.read-write` must be present.
class PathPickerInput extends StatelessWidget {
  const PathPickerInput({
    super.key,
    this.controller,
    this.value,
    this.placeholder,
    this.dialogTitle,
    this.onChanged,
    this.readOnly = false,
    this.buttonStyle = PathPickerButtonStyle.outline,
    this.mode = PathPickerMode.directory,
    this.allowedExtensions,
    this.initialDirectory,
    this.transformResult,
  });

  /// Text editing controller for the path input.
  /// Mutually exclusive with [value].
  final TextEditingController? controller;

  /// Current value displayed in the input when not using a [controller].
  /// Mutually exclusive with [controller].
  final String? value;

  /// Placeholder text shown when the input is empty.
  final String? placeholder;

  /// Label applied to the [XTypeGroup] when picking files. The OS sets the
  /// actual dialog title on desktop — this parameter is kept for API
  /// backwards-compatibility but only controls the filter label now.
  final String? dialogTitle;

  /// Called when a path is selected or the text changes.
  final ValueChanged<String>? onChanged;

  /// Whether the text input is read-only (only changeable via the picker).
  final bool readOnly;

  /// Visual style of the browse button.
  final PathPickerButtonStyle buttonStyle;

  /// Whether to pick a directory or a file.
  final PathPickerMode mode;

  /// Allowed file extensions when [mode] is [PathPickerMode.file].
  /// Example: `['json', 'yaml', 'txt']` (without dots).
  final List<String>? allowedExtensions;

  /// The directory the system dialog opens in initially.
  final String? initialDirectory;

  /// Optional transform applied to the picked path before setting it on
  /// the controller and calling [onChanged]. Useful for converting an
  /// absolute path to a relative one.
  final String Function(String absolutePath)? transformResult;

  bool get _directoryPickerUnsupported =>
      !kIsWeb && mode == PathPickerMode.directory && Platform.isIOS;

  Future<void> _pick() async {
    if (_directoryPickerUnsupported) {
      toast(
        'Directory picking is not supported on iOS',
        type: ToastType.warning,
      );
      return;
    }

    String? result;
    try {
      switch (mode) {
        case PathPickerMode.directory:
          result = await getDirectoryPath(
            initialDirectory: initialDirectory,
          );
        case PathPickerMode.file:
          final typeGroups = <XTypeGroup>[
            if (allowedExtensions != null && allowedExtensions!.isNotEmpty)
              XTypeGroup(
                label: dialogTitle ?? 'files',
                extensions: allowedExtensions,
              ),
          ];
          final XFile? picked = await openFile(
            acceptedTypeGroups: typeGroups,
            initialDirectory: initialDirectory,
          );
          result = picked?.path;
      }
    } catch (e, st) {
      debugPrint('PathPickerInput failed: $e\n$st');
      toast(
        'Could not open the system file picker',
        description: '$e',
        type: ToastType.error,
      );
      return;
    }

    if (result != null && result.isNotEmpty) {
      final transformed =
          transformResult != null ? transformResult!(result) : result;
      controller?.text = transformed;
      onChanged?.call(transformed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFile = mode == PathPickerMode.file;

    return Row(
      children: [
        Expanded(
          child: Input(
            controller: controller,
            initialValue: controller == null ? value : null,
            placeholder: placeholder,
            readOnly: readOnly,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        _buildButton(isFile),
      ],
    );
  }

  Widget _buildButton(bool isFile) {
    final icon =
        isFile ? LucideIcons.file_text : LucideIcons.folder;
    final iconAlt = isFile ? LucideIcons.file_text : LucideIcons.folder_open;
    final onPressed = _directoryPickerUnsupported ? null : _pick;

    switch (buttonStyle) {
      case PathPickerButtonStyle.outline:
        return Button(
          icon: icon,
          variant: ButtonVariant.outline,
          onPressed: onPressed,
        );
      case PathPickerButtonStyle.primary:
        return Button(
          size: ButtonSize.icon,
          icon: iconAlt,
          variant: ButtonVariant.primary,
          onPressed: onPressed,
        );
      case PathPickerButtonStyle.ghost:
        return DspatchIconButton(
          icon: icon,
          variant: IconButtonVariant.ghost,
          size: IconButtonSize.sm,
          tooltip: _directoryPickerUnsupported
              ? 'Not supported on iOS'
              : 'Browse',
          onPressed: onPressed,
        );
    }
  }
}

/// Convenience alias — a [PathPickerInput] pre-configured for directories.
typedef DirectoryPickerInput = PathPickerInput;

/// Convenience alias for the button style enum.
typedef DirectoryPickerButtonStyle = PathPickerButtonStyle;
