// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../engine_client/models/auth_state.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../features/auth/auth_controller.dart';

/// Shows a dialog if the user is not authenticated, explaining they need to
/// sign in. Returns `true` if the user is authenticated (proceed with action),
/// `false` if not (dialog shown, action cancelled).
Future<bool> requireAuth(BuildContext context, WidgetRef ref) async {
  final authState = ref.read(authStateProvider).valueOrNull;
  if (authState != null && authState.mode == AuthMode.connected) {
    return true;
  }

  final result = await DspatchDialog.show<bool>(
    context: context,
    maxWidth: 420,
    builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogHeader(children: [
            const DialogTitle(text: 'Sign in required'),
            const DialogDescription(
              text: 'You need a d:spatch account to use this feature. '
                  'Sign in to access the full community hub experience.',
            ),
          ]),
          DialogFooter(children: [
            Button(
              label: 'Cancel',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            Button(
              label: 'Sign In',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ]),
        ],
      ),
  );

  if (result == true) {
    await ref.read(authControllerProvider.notifier).logout();
    return false;
  }

  return false;
}
