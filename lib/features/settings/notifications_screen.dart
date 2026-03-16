// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/commands/commands.dart';

/// Notification preference key constants.
class _NotifKeys {
  static const newInquiry = 'notification.new_inquiry';
  static const highPriorityInquiry = 'notification.high_priority_inquiry';
  static const sessionCompleted = 'notification.session_completed';
  static const sessionFailed = 'notification.session_failed';
}

/// Event definitions for notification preferences.
const _notificationEvents = [
  (
    key: _NotifKeys.newInquiry,
    icon: LucideIcons.message_square,
    title: 'New inquiry',
    description: 'When an agent sends a new inquiry',
  ),
  (
    key: _NotifKeys.highPriorityInquiry,
    icon: LucideIcons.circle_alert,
    title: 'High-priority inquiry',
    description: 'When an agent sends an urgent inquiry',
  ),
  (
    key: _NotifKeys.sessionCompleted,
    icon: LucideIcons.circle_check,
    title: 'Session completed',
    description: 'When a session finishes successfully',
  ),
  (
    key: _NotifKeys.sessionFailed,
    icon: LucideIcons.circle_alert,
    title: 'Session failed',
    description: 'When a session terminates with an error',
  ),
];

/// Provider that loads notification preference values.
/// Defaults to true when unset.
final notificationPreferencesProvider =
    FutureProvider.autoDispose<Map<String, bool>>((ref) async {
  final client = ref.watch(engineClientProvider);
  final keys = [
    _NotifKeys.newInquiry,
    _NotifKeys.highPriorityInquiry,
    _NotifKeys.sessionCompleted,
    _NotifKeys.sessionFailed,
  ];

  final result = <String, bool>{};
  for (final key in keys) {
    try {
      final pref = await client.send(GetPreference(key: key));
      final value = pref.value;
      result[key] = value != null ? value == 'true' : true;
    } catch (_) {
      result[key] = true;
    }
  }
  return result;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Button(
                icon: LucideIcons.arrow_left,
                variant: ButtonVariant.ghost,
                onPressed: () => context.go('/settings'),
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          const Text(
            'Choose which events trigger desktop notifications.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: prefsAsync.when(
              loading: () => const Center(child: Spinner()),
              error: (e, _) => ErrorStateView(
                message: 'Error loading preferences: $e',
              ),
              data: (prefs) => ListView.separated(
                itemCount: _notificationEvents.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Spacing.sm),
                itemBuilder: (context, index) {
                  final event = _notificationEvents[index];
                  final enabled = prefs[event.key] ?? true;
                  return _NotificationToggle(
                    icon: event.icon,
                    title: event.title,
                    description: event.description,
                    value: enabled,
                    onChanged: (value) {
                      ref
                          .read(engineClientProvider)
                          .send(SetPreference(
                        key: event.key,
                        value: value.toString(),
                      ));
                      // Refresh preferences to reflect the change.
                      ref.invalidate(notificationPreferencesProvider);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          DspatchSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
