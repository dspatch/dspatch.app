// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/providers.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  @override
  FutureOr<void> build() {}

  Future<void> updateThemeMode(ThemeMode mode) async {
    final client = ref.read(engineClientProvider);
    await client.setPreference('theme_mode', mode.name);
    ref.read(themeModeProvider.notifier).state = mode;
  }
}
