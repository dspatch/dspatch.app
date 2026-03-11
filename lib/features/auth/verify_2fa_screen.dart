// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'widgets/auth_layout.dart';

/// 2FA verification screen shown during the login flow.
///
/// The user enters a 6-digit TOTP code from their authenticator app,
/// or can toggle to enter a one-time backup code instead.
class Verify2faScreen extends ConsumerStatefulWidget {
  const Verify2faScreen({super.key});

  @override
  ConsumerState<Verify2faScreen> createState() => _Verify2faScreenState();
}

class _Verify2faScreenState extends ConsumerState<Verify2faScreen> {
  bool _isLoading = false;
  String? _error;
  bool _useBackupCode = false;
  final _backupCodeController = TextEditingController();

  @override
  void dispose() {
    _backupCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(String code, {bool isBackupCode = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(sdkProvider).verify2Fa(
            code: code,
            isBackupCode: isBackupCode,
          );
      // Auth state becomes full -> route guard redirects to /sessions
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _handleBackupCodeSubmit() {
    final code = _backupCodeController.text.trim();
    if (code.isEmpty) return;
    _handleVerify(code, isBackupCode: true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
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
                            'Enter the 6-digit code from your authenticator app to continue.',
                      ),
                    ],
                  ),
                ),
                CardContent(
                  child: _useBackupCode
                      ? _buildBackupCodeInput()
                      : _buildOtpInput(),
                ),
                CardFooter(
                  child: Button(
                    label: _useBackupCode
                        ? 'Use authenticator code'
                        : 'Use backup code instead',
                    variant: ButtonVariant.link,
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _useBackupCode = !_useBackupCode;
                              _error = null;
                            });
                          },
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(
              title: 'Verification failed',
              message: _error!,
            ),
          ],

          const SizedBox(height: Spacing.lg),
          Button(
            label: 'Cancel',
            variant: ButtonVariant.ghost,
            icon: LucideIcons.arrow_left,
            onPressed: _isLoading
                ? null
                : () => ref.read(sdkProvider).logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: Center(child: Spinner()),
      );
    }
    return Center(
      child: InputOTP(
        length: 6,
        onCompleted: _handleVerify,
      ),
    );
  }

  Widget _buildBackupCodeInput() {
    return Column(
      children: [
        Field(
          label: 'Backup code',
          child: Input(
            controller: _backupCodeController,
            placeholder: 'Enter a backup code',
            prefix: const Icon(LucideIcons.key,
                size: 18, color: AppColors.mutedForeground),
            disabled: _isLoading,
            onSubmitted: (_) => _handleBackupCodeSubmit(),
          ),
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: double.infinity,
          child: Button(
            label: 'Verify',
            variant: ButtonVariant.primary,
            loading: _isLoading,
            onPressed: _isLoading ? null : _handleBackupCodeSubmit,
          ),
        ),
      ],
    );
  }
}
