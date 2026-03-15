// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';
import 'auth_controller.dart';
import 'widgets/auth_layout.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isLoading = false;
  String? _error;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify(String code) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success =
          await ref.read(authControllerProvider.notifier).verifyEmail(code);
      if (!mounted) return;
      if (!success) {
        setState(() => _isLoading = false);
      }
      // Router redirects based on backendAuthStateProvider scope.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      toast('Verification code resent', type: ToastType.success);

      setState(() => _resendCooldown = 60);
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) timer.cancel();
        });
      });
    } catch (e) {
      if (!mounted) return;
      toast('Failed to resend: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backendAuth = ref.watch(backendAuthStateProvider);
    final email = backendAuth?.email ?? 'your email';

    return AuthLayout(
      stepperStep: 2,
      stepperTotal: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DspatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardTitle(text: 'Verify your email'),
                      CardDescription(
                        text: 'Enter the 6-digit code sent to $email.',
                      ),
                    ],
                  ),
                ),
                CardContent(
                  child: Column(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(Spacing.lg),
                          child: Spinner(),
                        )
                      else
                        Center(
                          child: InputOTP(
                            length: 6,
                            onCompleted: _handleVerify,
                          ),
                        ),
                    ],
                  ),
                ),
                CardFooter(
                  child: Button(
                    label: _resendCooldown > 0
                        ? 'Resend code ($_resendCooldown s)'
                        : 'Resend code',
                    variant: ButtonVariant.link,
                    onPressed: _resendCooldown > 0 ? null : _handleResend,
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
        ],
      ),
    );
  }
}
