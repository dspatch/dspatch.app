// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../engine_client/models/auth_token.dart';
import '../../models/commands/command.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _devices = [];
  String? _currentDeviceId;

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

      final tokenStore = ref.read(secureTokenStoreProvider);
      final creds = await tokenStore.loadDeviceCredentials(token.username);

      final backend = ref.read(backendAuthProvider);
      final devices = await backend.listDevices(token: token.token);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _devices = devices;
        _currentDeviceId = creds?.deviceId;
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
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull;
    final onlineDevices = ref.watch(onlineDevicesProvider).valueOrNull ?? [];

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
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
                label: 'Refresh',
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                icon: LucideIcons.refresh_cw,
                onPressed: _loadDevices,
              ),
              const SizedBox(width: Spacing.xs),
              Button(
                label: 'Approve device',
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                icon: LucideIcons.plus,
                onPressed: () async {
                  final result =
                      await context.push<bool>('/devices/approve');
                  if (result == true) _loadDevices();
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Sync status bar
          _SyncStatusBar(syncStatus: syncStatus),
          const SizedBox(height: Spacing.lg),

          // Error
          if (_error != null) ...[
            ErrorAlert(title: 'Error', message: _error!),
            const SizedBox(height: Spacing.md),
          ],

          // Device list
          if (_loading)
            const Center(child: Spinner())
          else if (_devices.isEmpty)
            const EmptyState(
              icon: LucideIcons.smartphone,
              title: 'No devices',
              description:
                  'No devices are registered to your account yet.',
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _devices.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Spacing.sm),
                itemBuilder: (context, index) {
                  final d = _devices[index] as Map<String, dynamic>;
                  final id = d['id'] as String;
                  final name = d['name'] as String? ?? 'Unknown';
                  final deviceType = d['device_type'] as String?;
                  final platform = d['platform'] as String?;
                  final approved = d['approved'] as bool? ?? false;
                  final isCurrent = id == _currentDeviceId;
                  final isOnline = onlineDevices.contains(id);

                  return _DeviceCard(
                    name: name,
                    platform: platform,
                    deviceType: deviceType,
                    icon: _deviceIcon(deviceType),
                    isCurrent: isCurrent,
                    isOnline: isOnline || isCurrent,
                    isConnected: isOnline,
                    approved: approved,
                    onRevoke: isCurrent
                        ? null
                        : () => _revokeDevice(id, name),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sync status bar
// ---------------------------------------------------------------------------

class _SyncStatusBar extends ConsumerStatefulWidget {
  final Map<String, dynamic>? syncStatus;
  const _SyncStatusBar({required this.syncStatus});

  @override
  ConsumerState<_SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends ConsumerState<_SyncStatusBar> {
  bool _syncing = false;
  Map<String, dynamic>? _lastSyncResult;
  String? _lastSyncError;

  Future<void> _triggerSync() async {
    setState(() {
      _syncing = true;
      _lastSyncResult = null;
      _lastSyncError = null;
    });

    try {
      final client = ref.read(engineClientProvider);
      final response = await client.send(
        RawEngineCommand(method: 'trigger_sync', params: {}),
      );
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _lastSyncResult = response.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _lastSyncError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = widget.syncStatus;
    final state = syncStatus?['state'] as String? ?? 'unknown';
    final deviceId = syncStatus?['device_id'] as String? ?? 'unknown';
    final pendingCount = syncStatus?['pending_count'] as int? ?? 0;
    final connectedPeers = syncStatus?['connected_peers'] as int? ?? 0;
    final diag = syncStatus?['diagnostics'] as Map<String, dynamic>? ?? {};

    final (Color color, String label, IconData icon) = switch (state) {
      'syncing' => (AppColors.success, 'Sync active', LucideIcons.refresh_cw),
      'synced' => (AppColors.success, 'Synced', LucideIcons.circle_check),
      'offline' => (AppColors.warning, 'Offline', LucideIcons.wifi_off),
      'signal_failed' => (AppColors.error, 'Signal failed', LucideIcons.circle_x),
      'disabled' => (AppColors.mutedForeground, 'Sync disabled', LucideIcons.pause),
      _ => (AppColors.mutedForeground, 'Unknown: $state', LucideIcons.circle_alert),
    };

    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main status row
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: Spacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              if (connectedPeers > 0) ...[
                PulsingDot(color: AppColors.success, size: 8),
                const SizedBox(width: 6),
                Text(
                  '$connectedPeers connected',
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
                const SizedBox(width: Spacing.md),
              ],
              if (pendingCount > 0) ...[
                DspatchBadge(
                  label: '$pendingCount pending',
                  variant: BadgeVariant.secondary,
                ),
                const SizedBox(width: Spacing.sm),
              ],
            ],
          ),
          // Diagnostics (debug builds only)
          if (kDebugMode) ...[
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.md,
              runSpacing: 4,
              children: [
                _DiagChip('Device ID', deviceId == 'local' ? 'not set' : '${deviceId.substring(0, 8.clamp(0, deviceId.length))}...', deviceId != 'local'),
                _DiagChip('Database', null, diag['database_open'] == true),
                _DiagChip('Identity key', null, diag['identity_key_stored'] == true),
                _DiagChip('Signal', null, diag['signal_bootstrapped'] == true),
                _DiagChip('Sync engine', null, diag['sync_engine_running'] == true),
                _DiagChip('Backend WS', null, diag['ws_client_connected'] == true),
                _DiagChip('Schema', 'v${diag['schema_version'] ?? '?'}', (diag['schema_version'] ?? 0) >= 16),
                _DiagChip('Triggers', '${diag['trigger_count'] ?? 0}', (diag['trigger_count'] ?? 0) > 0),
                _DiagChip('Trigger device', diag['trigger_device_id'] as String? ?? '?', diag['trigger_device_id'] != null && diag['trigger_device_id'] != 'local' && diag['trigger_device_id'] != 'TABLE_MISSING'),
              ],
            ),
            if (diag['last_error'] != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                diag['last_error'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: Spacing.sm),
            // Sync Now button + result
            Row(
              children: [
                Button(
                  label: _syncing ? 'Syncing...' : 'Sync Now',
                  variant: ButtonVariant.outline,
                  size: ButtonSize.xs,
                  icon: LucideIcons.refresh_cw,
                  onPressed: _syncing ? null : _triggerSync,
                ),
                if (_lastSyncResult != null) ...[
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Sent to ${_lastSyncResult!['peers_synced']} peers, ${_lastSyncResult!['pending_after']} pending',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                  ),
                ],
              ],
            ),
            // Sync result details
            if (_lastSyncResult != null && _lastSyncResult!['results'] is List) ...[
              const SizedBox(height: Spacing.xs),
              for (final r in (_lastSyncResult!['results'] as List))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    r['status'] == 'ok'
                        ? '${r['peer']}: ${r['changes_sent']} changes sent'
                        : '${r['peer']}: ${r['error']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: r['status'] == 'ok' ? AppColors.success : AppColors.error,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                ),
            ],
            if (_lastSyncError != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                _lastSyncError!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ], // end kDebugMode
        ],
      ),
    );
  }
}

class _DiagChip extends StatelessWidget {
  final String label;
  final String? detail;
  final bool ok;
  const _DiagChip(this.label, this.detail, this.ok);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? LucideIcons.circle_check : LucideIcons.circle_x,
          size: 12,
          color: ok ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 4),
        Text(
          detail != null ? '$label: $detail' : label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Device card
// ---------------------------------------------------------------------------

class _DeviceCard extends StatelessWidget {
  final String name;
  final String? platform;
  final String? deviceType;
  final IconData icon;
  final bool isCurrent;
  final bool isOnline;
  final bool isConnected;
  final bool approved;
  final VoidCallback? onRevoke;

  const _DeviceCard({
    required this.name,
    required this.platform,
    required this.deviceType,
    required this.icon,
    required this.isCurrent,
    required this.isOnline,
    required this.isConnected,
    required this.approved,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      child: Row(
        children: [
          // Online indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.muted,
            ),
          ),
          const SizedBox(width: Spacing.sm),

          // Device icon
          Icon(
            icon,
            size: 20,
            color: isCurrent ? AppColors.primary : AppColors.mutedForeground,
          ),
          const SizedBox(width: Spacing.md),

          // Name + platform
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: Spacing.xs),
                      const DspatchBadge(
                        label: 'This device',
                        variant: BadgeVariant.primary,
                      ),
                    ],
                  ],
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

          // Status badges
          if (!approved)
            const DspatchBadge(
              label: 'Pending',
              variant: BadgeVariant.secondary,
            )
          else if (isConnected && !isCurrent)
            const DspatchBadge(
              label: 'Connected',
              variant: BadgeVariant.success,
            )
          else if (isOnline && !isCurrent)
            const DspatchBadge(
              label: 'Online',
              variant: BadgeVariant.info,
            )
          else if (!isCurrent)
            const DspatchBadge(
              label: 'Offline',
              variant: BadgeVariant.outline,
            ),

          // Revoke button
          if (onRevoke != null) ...[
            const SizedBox(width: Spacing.sm),
            Button(
              label: 'Revoke',
              variant: ButtonVariant.ghost,
              size: ButtonSize.sm,
              onPressed: onRevoke,
            ),
          ],
        ],
      ),
    );
  }
}
