// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'auth_controller.dart';
import 'widgets/auth_layout.dart';

class BackupCodesScreen extends ConsumerStatefulWidget {
  const BackupCodesScreen({super.key});

  @override
  ConsumerState<BackupCodesScreen> createState() => _BackupCodesScreenState();
}

class _BackupCodesScreenState extends ConsumerState<BackupCodesScreen> {
  bool _isAcknowledging = false;

  Future<void> _acknowledge() async {
    setState(() => _isAcknowledging = true);

    await ref.read(authControllerProvider.notifier).acknowledgeBackupCodes();
    // Controller clears pending codes and advances scope to device_registration.
    // Router redirects to /auth/device-pairing.
  }

  @override
  Widget build(BuildContext context) {
    final codes = ref.watch(pendingBackupCodesProvider);

    if (codes == null || codes.isEmpty) {
      return AuthLayout(
        stepperStep: 4,
        stepperTotal: 5,
        child: ErrorAlert(
          title: 'Missing backup codes',
          message: 'No backup codes found. '
              'Please go back and complete the 2FA setup.',
        ),
      );
    }

    return AuthLayout(
      stepperStep: 4,
      stepperTotal: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning
          Alert(
            variant: AlertVariant.warning,
            children: [
              AlertTitle(text: 'Save your backup codes'),
              AlertDescription(
                text:
                    'Store these codes in a secure location. Each code can only be used once to sign in if you lose access to your authenticator.',
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // Codes card
          DspatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(text: 'Recovery codes'),
                      CardDescription(
                        text: 'Keep these somewhere safe and accessible.',
                      ),
                    ],
                  ),
                ),
                CardContent(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Wrap(
                      spacing: Spacing.md,
                      runSpacing: Spacing.sm,
                      children: codes
                          .map(
                            (code) => SizedBox(
                              width: 140,
                              child: Text(
                                code,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  color: AppColors.foreground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                CardFooter(
                  child: Expanded(
                    child: Row(
                      children: [
                        CopyButton(
                          textToCopy: codes.join('\n'),
                          iconSize: 16,
                        ),
                        const Spacer(),
                        Button(
                          label: "I've saved my codes",
                          variant: ButtonVariant.primary,
                          loading: _isAcknowledging,
                          onPressed: _isAcknowledging ? null : _acknowledge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
