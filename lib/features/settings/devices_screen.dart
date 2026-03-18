// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_token.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final backend = ref.read(backendAuthProvider);
      final response = await backend.listDevices(token: token.token);
      final devices = response['devices'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _loading = false;
        _devices = devices;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load devices: $e';
      });
    }
  }

  Future<void> _revokeDevice(String deviceId, String name) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Revoke device',
      description: 'Remove "$name" from your account? This cannot be undone.',
      confirmLabel: 'Revoke',
      confirmVariant: ButtonVariant.destructive,
    );

    if (confirmed != true) return;

    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final backend = ref.read(backendAuthProvider);
      await backend.revokeDevice(
        token: token.token,
        deviceId: deviceId,
      );
      await _loadDevices();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to revoke device: $e');
    }
  }

  IconData _deviceIcon(String? deviceType) {
    return switch (deviceType) {
      'mobile' => LucideIcons.smartphone,
      'browser' => LucideIcons.globe,
      _ => LucideIcons.monitor,
    };
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
                onPressed: () => context.go('/settings'),
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Button(
                label: 'Approve device',
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                icon: LucideIcons.plus,
                onPressed: () async {
                  final result =
                      await context.push<bool>('/settings/devices/approve');
                  if (result == true) _loadDevices();
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          if (_error != null) ...[
            ErrorAlert(title: 'Error', message: _error!),
            const SizedBox(height: Spacing.md),
          ],
          if (_loading)
            const Center(child: Spinner())
          else if (_devices.isEmpty)
            const EmptyState(
              icon: LucideIcons.smartphone,
              title: 'No devices',
              description: 'No devices are registered to your account.',
            )
          else
            ..._devices.map((device) {
              final d = device as Map<String, dynamic>;
              final id = d['id'] as String;
              final name = d['name'] as String? ?? 'Unknown';
              final deviceType = d['device_type'] as String?;
              final platform = d['platform'] as String?;
              final approved = d['approved'] as bool? ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: DspatchCard(
                  child: Row(
                    children: [
                      Icon(
                        _deviceIcon(deviceType),
                        size: 20,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.foreground,
                              ),
                            ),
                            Text(
                              '${platform ?? 'unknown'} \u2022 ${deviceType ?? 'unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!approved)
                        const DspatchBadge(
                          label: 'Pending',
                          variant: BadgeVariant.secondary,
                        ),
                      if (approved)
                        const DspatchBadge(
                          label: 'Active',
                          variant: BadgeVariant.outline,
                        ),
                      const SizedBox(width: Spacing.sm),
                      Button(
                        label: 'Revoke',
                        variant: ButtonVariant.ghost,
                        size: ButtonSize.sm,
                        onPressed: () => _revokeDevice(id, name),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
