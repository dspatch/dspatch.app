// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../../di/providers.dart';
import 'widgets/auth_layout.dart';

class TotpSetupScreen extends ConsumerStatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  ConsumerState<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends ConsumerState<TotpSetupScreen> {
  TotpSetupData? _setupData;
  bool _isLoadingSetup = true;
  bool _isConfirming = false;
  String? _setupError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    try {
      final data = await ref.read(sdkProvider).setup2Fa();

      if (!mounted) return;

      setState(() {
        _setupData = data;
        _isLoadingSetup = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _setupError = e.toString();
        _isLoadingSetup = false;
      });
    }
  }

  Future<void> _handleConfirm(String code) async {
    setState(() {
      _isConfirming = true;
      _confirmError = null;
    });

    try {
      final data = await ref.read(sdkProvider).confirm2Fa(code: code);
      // Stash backup codes so BackupCodesScreen can display them.
      ref.read(pendingBackupCodesProvider.notifier).state = data.backupCodes;
      // Scope is now awaitingBackupConfirmation -- the route guard will
      // redirect to /auth/backup-codes automatically.
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isConfirming = false;
        _confirmError = e.toString();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      stepperStep: 3,
      stepperTotal: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DspatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(text: 'Two-factor authentication'),
                      CardDescription(
                        text:
                            'Scan the QR code with your authenticator app, then enter the code to confirm.',
                      ),
                    ],
                  ),
                ),
                CardContent(
                  child: _isLoadingSetup
                      ? const Padding(
                          padding: EdgeInsets.all(Spacing.lg),
                          child: Center(child: Spinner()),
                        )
                      : _setupError != null
                          ? _buildSetupError()
                          : _buildSetupContent(),
                ),
              ],
            ),
          ),

          if (_confirmError != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(
              title: 'Verification failed',
              message: _confirmError!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupError() {
    return ErrorStateView(
      message: 'Setup failed: $_setupError',
      onRetry: () {
        setState(() {
          _isLoadingSetup = true;
          _setupError = null;
        });
        _loadSetupData();
      },
    );
  }

  Widget _buildSetupContent() {
    final data = _setupData!;

    return Column(
      children: [
        // QR code
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: QrImageView(
            data: data.totpUri,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Manual entry secret
        const Text(
          "Can't scan? Enter this secret manually:",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  data.secret,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 1.5,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              CopyButton(
                textToCopy: data.secret,
                iconSize: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),

        // Confirmation OTP input
        const Text(
          'Enter the 6-digit code from your authenticator:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (_isConfirming)
          const Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: Spinner(),
          )
        else
          Center(
            child: InputOTP(
              length: 6,
              onCompleted: _handleConfirm,
            ),
          ),
      ],
    );
  }
}
