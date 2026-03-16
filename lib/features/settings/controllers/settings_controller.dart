// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/providers.dart';
import '../../../models/commands/commands.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<void> build() async {}

  Future<void> updateThemeMode(ThemeMode mode) async {
    final client = ref.read(engineClientProvider);
    await client.send(SetPreference(key: 'theme_mode', value: mode.name));
    ref.read(themeModeProvider.notifier).state = mode;
  }
}
