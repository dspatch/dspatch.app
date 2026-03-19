// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sets the native window title bar color on desktop platforms.
abstract final class TitleBarService {
  static const _channel = MethodChannel('dev.dspatch/titlebar');

  /// Update the title bar to [color]. No-op on non-desktop platforms.
  static Future<void> setColor(Color color) async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

    try {
      await _channel.invokeMethod('setColor', {
        'r': (color.r * 255.0).round().clamp(0, 255),
        'g': (color.g * 255.0).round().clamp(0, 255),
        'b': (color.b * 255.0).round().clamp(0, 255),
      });
    } on MissingPluginException catch (e) {
      debugPrint('[TitleBarService] setColor: plugin not available: $e');
    } catch (e) {
      debugPrint('[TitleBarService] setColor failed: $e');
    }
  }
}
