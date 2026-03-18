// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/platform_info.dart';
import '../../di/providers.dart';
import '../../engine_client/backend_auth.dart';
import '../../engine_client/models/auth_token.dart';
import '../auth/utils/sas_derivation.dart';

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
  String? _sasCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final scanned = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _QrScannerDialog(),
    );
    if (scanned == null || !mounted) return;

    // The QR payload is the opaque qr_data string from the pairing initiation.
    // Submit it directly via the QR approval method.
    await _submitQrPayload(scanned);
  }

  Future<void> _submitQrPayload(String qrData) async {
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
          'method': 'qr',
          'qr_data': qrData,
        },
      );

      _deviceId = response['device_id'] as String;

      if (response['requires_sas'] == true) {
        final approverKey = response['approver_identity_key'] as String?;
        final bundle = response['public_key_bundle'] as Map<String, dynamic>?;
        final newDeviceKey = bundle?['identity_key'] as String?;

        if (approverKey != null && newDeviceKey != null) {
          _sasCode = await deriveSas(newDeviceKey, approverKey);
        }

        if (!mounted) return;
        setState(() {
          _loading = false;
          _showSas = true;
        });
      } else {
        if (!mounted) return;
        context.pop(true);
      }
    } on BackendAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.statusCode) {
        400 => e.message,
        410 => 'No pending pairing requests. The QR code may have expired.',
        404 => 'Invalid QR code. Please try again.',
        _ => 'Failed to verify QR code: ${e.message}',
      };
      setState(() {
        _loading = false;
        _error = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to verify QR code: $e';
      });
    }
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

      if (response['requires_sas'] == true) {
        // Derive SAS from both identity keys
        final approverKey = response['approver_identity_key'] as String?;
        final bundle = response['public_key_bundle'] as Map<String, dynamic>?;
        final newDeviceKey = bundle?['identity_key'] as String?;

        if (approverKey != null && newDeviceKey != null) {
          _sasCode = await deriveSas(newDeviceKey, approverKey);
        }

        if (!mounted) return;
        setState(() {
          _loading = false;
          _showSas = true;
        });
      } else {
        // QR path — approval is complete, no SAS needed
        if (!mounted) return;
        context.pop(true);
      }
    } on BackendAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.statusCode) {
        400 => e.message,
        410 => 'No pending pairing requests. The code may have expired.',
        404 => 'Invalid pairing code. Please check and try again.',
        _ => 'Failed to verify code: ${e.message}',
      };
      setState(() {
        _loading = false;
        _error = message;
      });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    label: 'Verify code',
                    variant: ButtonVariant.primary,
                    loading: _loading,
                    onPressed: _loading ? null : _submitCode,
                  ),
                  if (PlatformInfo.isMobile) ...[
                    const SizedBox(height: Spacing.sm),
                    Button(
                      label: 'Scan QR code',
                      variant: ButtonVariant.outline,
                      icon: LucideIcons.scan,
                      loading: _loading,
                      onPressed: _loading ? null : _scanQrCode,
                    ),
                  ],
                ],
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
                  child: Center(
                    child: Text(
                      _sasCode ?? '------',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Mono',
                        letterSpacing: 6,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  'Both devices should display the same code. '
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
            child: Expanded(
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
          ),
        ],
      ),
    );
  }
}

/// Full-screen dialog that uses the device camera to scan a QR code.
/// Returns the raw QR string via [Navigator.pop] on successful detection.
class _QrScannerDialog extends StatefulWidget {
  const _QrScannerDialog();

  @override
  State<_QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<_QrScannerDialog> {
  final _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                Navigator.pop(context, barcode!.rawValue!);
              }
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + Spacing.sm,
            right: Spacing.md,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Instruction text
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + Spacing.xl,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Point your camera at the QR code\non the new device',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
