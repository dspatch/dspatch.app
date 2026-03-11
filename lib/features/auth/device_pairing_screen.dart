// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dspatch_ui/dspatch_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';
import 'widgets/auth_layout.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  bool _isLoading = false;
  String? _error;

  String get _hostname => Platform.localHostname;

  String get _platformName {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Desktop';
  }

  String get _platformId {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'linux';
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _error = null;
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

      // Sign the pre-key with the identity key
      final signedPreKeyBytes =
          Uint8List.fromList(signedPreKeyPublic.bytes);
      final signature = await ed25519.sign(
        signedPreKeyBytes,
        keyPair: identityKeyPair,
      );

      // Build the hex representation of the private key so the Rust SDK
      // can persist it per-user.
      final identityPrivateBytes = await identityKeyPair.extractPrivateKeyBytes();
      final identityKeyHex =
          _bytesToHex(Uint8List.fromList(identityPrivateBytes));

      final request = DeviceRegistrationRequest(
        name: _hostname,
        deviceType: 'desktop',
        platform: _platformId,
        identityKey: Uint8List.fromList(identityPublicKey.bytes),
        signedPreKey: signedPreKeyBytes,
        signedPreKeyId: 1,
        signedPreKeySignature: Uint8List.fromList(signature.bytes),
        oneTimePreKeys: const [],
      );

      await ref.read(sdkProvider).registerDevice(
            request: request,
            identityKeyHex: identityKeyHex,
          );
      // Auth state becomes full -> route guard redirects to /sessions
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Device registration failed: $e';
      });
    }
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      stepperStep: 5,
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
                      CardTitle(text: 'Register this device'),
                      CardDescription(
                        text:
                            'Link this device to your account for secure, end-to-end encrypted sync.',
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
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.monitor,
                          size: 32,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: Spacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hostname,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_platformName \u2022 Desktop',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                CardFooter(
                  child: Expanded(
                    child: Button(
                      label: 'Register device',
                      variant: ButtonVariant.primary,
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _handleRegister,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(
              title: 'Registration failed',
              message: _error!,
            ),
          ],
        ],
      ),
    );
  }
}
