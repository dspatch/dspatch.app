// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_token.dart';

class PairingApprovalScreen extends ConsumerStatefulWidget {
  const PairingApprovalScreen({super.key});

  @override
  ConsumerState<PairingApprovalScreen> createState() =>
      _PairingApprovalScreenState();
}

class _PairingApprovalScreenState
    extends ConsumerState<PairingApprovalScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  // SAS verification state
  bool _showSas = false;
  String? _deviceId;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 8) {
      setState(() => _error = 'Code must be 8 digits.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final backend = ref.read(backendAuthProvider);
      final response = await backend.approvePairing(
        token: token.token,
        body: {
          'method': 'numeric',
          'numeric_code': code,
        },
      );

      _deviceId = response['device_id'] as String;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _showSas = response['requires_sas'] == true;
      });

      // If no SAS required (QR path), approval is complete
      if (!_showSas) {
        if (mounted) context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to verify code: $e';
      });
    }
  }

  Future<void> _confirmSas(bool confirmed) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final backend = ref.read(backendAuthProvider);
      await backend.verifySas(
        token: token.token,
        deviceId: _deviceId!,
        sasConfirmed: confirmed,
      );

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'SAS verification failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Button(
                label: 'Back',
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                icon: LucideIcons.arrow_left,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                'Approve device',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          if (!_showSas) _buildCodeEntry() else _buildSasVerification(),
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(title: 'Error', message: _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeEntry() {
    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(text: 'Enter pairing code'),
                CardDescription(
                  text: 'Enter the 8-digit code shown on the new device.',
                ),
              ],
            ),
          ),
          CardContent(
            child: Input(
              controller: _codeController,
              placeholder: '12345678',
              keyboardType: TextInputType.number,
            ),
          ),
          CardFooter(
            child: Expanded(
              child: Button(
                label: 'Verify code',
                variant: ButtonVariant.primary,
                loading: _loading,
                onPressed: _loading ? null : _submitCode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSasVerification() {
    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(text: 'Verify device identity'),
                CardDescription(
                  text:
                      'Confirm that the code below matches what is shown on the new device.',
                ),
              ],
            ),
          ),
          CardContent(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shield_check,
                            size: 24, color: AppColors.primary),
                        SizedBox(width: Spacing.sm),
                        Text(
                          'SAS verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  'Both devices should display the same verification code. '
                  'If they match, tap Confirm. If not, tap Reject to cancel.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          CardFooter(
            child: Row(
              children: [
                Expanded(
                  child: Button(
                    label: 'Reject',
                    variant: ButtonVariant.outline,
                    loading: _loading,
                    onPressed: _loading ? null : () => _confirmSas(false),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Button(
                    label: 'Confirm',
                    variant: ButtonVariant.primary,
                    loading: _loading,
                    onPressed: _loading ? null : () => _confirmSas(true),
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
