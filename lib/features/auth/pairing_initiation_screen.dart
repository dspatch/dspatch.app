// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_phase.dart';
import '../../engine_client/models/auth_token.dart';
import 'utils/sas_derivation.dart';
import 'widgets/auth_layout.dart';

class PairingInitiationScreen extends ConsumerStatefulWidget {
  const PairingInitiationScreen({super.key});

  @override
  ConsumerState<PairingInitiationScreen> createState() =>
      _PairingInitiationScreenState();
}

class _PairingInitiationScreenState
    extends ConsumerState<PairingInitiationScreen> {
  bool _loading = true;
  String? _error;
  String? _qrData;
  String? _numericCode;
  String? _deviceId;
  String? _identityKeyHex;
  DateTime? _expiresAt;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  String? _sasStatus; // null = not yet, 'awaiting_sas', 'approved'
  String? _sasCode;
  String? _identityKeyB64; // Our public key base64, for SAS derivation

  @override
  void initState() {
    super.initState();
    _initiatePairing();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _platformId {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'linux';
  }

  Future<void> _initiatePairing() async {
    setState(() {
      _loading = true;
      _error = null;
      _sasStatus = null;
    });

    try {
      // Generate Ed25519 identity key pair
      final ed25519 = Ed25519();
      final identityKeyPair = await ed25519.newKeyPair();
      final identityPublicKey = await identityKeyPair.extractPublicKey();

      // Generate X25519 signed pre-key pair
      final x25519 = X25519();
      final signedPreKeyPair = await x25519.newKeyPair();
      final signedPreKeyPublic = await signedPreKeyPair.extractPublicKey();

      final signedPreKeyBytes =
          Uint8List.fromList(signedPreKeyPublic.bytes);
      final signature = await ed25519.sign(
        signedPreKeyBytes,
        keyPair: identityKeyPair,
      );

      // Store base64 public key for SAS derivation later
      _identityKeyB64 = base64.encode(identityPublicKey.bytes);

      // Build hex private key for persistence
      final identityPrivateBytes =
          await identityKeyPair.extractPrivateKeyBytes();
      _identityKeyHex = identityPrivateBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      final request = <String, dynamic>{
        'name': Platform.localHostname,
        'device_type': 'desktop',
        'platform': _platformId,
        'identity_key': identityPublicKey.bytes,
        'signed_pre_key': signedPreKeyBytes,
        'signed_pre_key_id': 1,
        'signed_pre_key_signature': signature.bytes,
        'one_time_pre_keys': <List<int>>[],
      };

      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) {
        setState(() {
          _loading = false;
          _error = 'No valid authentication token.';
        });
        return;
      }

      final backend = ref.read(backendAuthProvider);
      final response = await backend.initiatePairing(
        token: token.token,
        body: request,
      );

      _deviceId = response['device_id'] as String;
      _qrData = response['qr_data'] as String;
      _numericCode = response['numeric_code'] as String;
      _expiresAt = DateTime.parse(response['expires_at'] as String);
      _remaining = _expiresAt!.difference(DateTime.now());

      if (!mounted) return;
      setState(() => _loading = false);

      // Start polling every 3 seconds
      _pollTimer =
          Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());

      // Start countdown timer
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = _expiresAt!.difference(DateTime.now());
        if (remaining.isNegative) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            setState(
                () => _error = 'Pairing code expired. Please try again.');
          }
        } else {
          if (mounted) setState(() => _remaining = remaining);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to initiate pairing: $e';
      });
    }
  }

  Future<void> _pollStatus() async {
    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final backend = ref.read(backendAuthProvider);
      final response = await backend.pairingStatus(
        token: token.token,
        deviceId: _deviceId!,
      );

      final status = response['status'] as String;

      if (status == 'awaiting_sas') {
        final approverKey = response['approver_identity_key'] as String?;
        if (approverKey != null && _identityKeyB64 != null && _sasCode == null) {
          _sasCode = await deriveSas(_identityKeyB64!, approverKey);
        }
        if (mounted) setState(() => _sasStatus = 'awaiting_sas');
      } else if (status == 'approved') {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        await _onApproved(response);
      } else if (status == 'expired') {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        if (mounted) {
          setState(
              () => _error = 'Pairing code expired. Please try again.');
        }
      }
    } catch (_) {
      // Polling error — continue polling silently
    }
  }

  Future<void> _onApproved(Map<String, dynamic> response) async {
    final deviceId = response['device_id'] as String;
    final newToken = response['token'] as String;
    final expiresAt = response['expires_at'] as int;
    final username = response['username'] as String;
    final email = (response['email'] as String?) ?? '';

    // Save device credentials to OS keyring
    final tokenStore = ref.read(secureTokenStoreProvider);
    await tokenStore.saveDeviceCredentials(
      username: username,
      deviceId: deviceId,
      identityKeyHex: _identityKeyHex!,
    );

    // Save session credentials
    await tokenStore.saveSession(
      backendToken: newToken,
      expiresAt: expiresAt,
      scope: 'full',
      username: username,
      email: email,
    );

    // Transition to authenticated
    final backendToken = BackendToken(
      token: newToken,
      expiresAt: expiresAt,
      scope: 'full',
      username: username,
      email: email,
    );

    if (!mounted) return;
    ref.read(authTokenProvider.notifier).state = backendToken;
    ref.read(authPhaseProvider.notifier).state = AuthPhase.authenticated;
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      stepperStep: 5,
      stepperTotal: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const DspatchCard(
              child: Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: Center(child: Spinner()),
              ),
            )
          else if (_error != null)
            _buildError()
          else
            _buildPairingDisplay(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorAlert(
          title: 'Pairing failed',
          message: _error!,
        ),
        const SizedBox(height: Spacing.md),
        Button(
          label: 'Try again',
          variant: ButtonVariant.primary,
          onPressed: _initiatePairing,
        ),
      ],
    );
  }

  Widget _buildPairingDisplay() {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(text: 'Pair this device'),
                CardDescription(
                  text:
                      'Open d:spatch on an existing device and approve this pairing request.',
                ),
              ],
            ),
          ),
          CardContent(
            child: Column(
              children: [
                if (_sasStatus == 'awaiting_sas') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.shield_check,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: Spacing.sm),
                            Text(
                              'Verify this code matches your other device',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          _sasCode ?? '------',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Mono',
                            letterSpacing: 6,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                // QR Code
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                // Numeric code
                const Text(
                  'Or enter this code:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _numericCode!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DM Mono',
                    letterSpacing: 4,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // Countdown
                Text(
                  'Expires in ${minutes}m ${seconds.toString().padLeft(2, '0')}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
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
