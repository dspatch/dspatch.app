// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../engine_client/models/auth_state.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isConnected = authState?.mode == AuthMode.connected;

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
                  'Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          if (isConnected)
            _ConnectedAccountInfo(
              username: authState?.username ?? 'User',
              email: authState?.email,
              onLogout: () => ref.read(engineClientProvider).logout(),
            )
          else
            _GuestAccountInfo(
              onSignIn: () => ref.read(engineClientProvider).logout(),
            ),
        ],
      ),
    );
  }
}

class _ConnectedAccountInfo extends StatelessWidget {
  const _ConnectedAccountInfo({
    required this.username,
    this.email,
    required this.onLogout,
  });

  final String username;
  final String? email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = (username.isNotEmpty ? username : '?')
        .characters
        .first
        .toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DspatchCard(
          child: Row(
            children: [
              DspatchAvatar(
                fallback: initial,
                size: 48,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (email != null)
                      Text(
                        email!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              const DspatchBadge(
                label: 'Free',
                variant: BadgeVariant.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Button(
          label: 'Log out',
          icon: LucideIcons.log_out,
          variant: ButtonVariant.destructive,
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _GuestAccountInfo extends StatelessWidget {
  const _GuestAccountInfo({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DspatchCard(
          child: Row(
            children: [
              Icon(
                LucideIcons.user,
                size: 32,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guest Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Text(
                      'You\'re using d:spatch in local-only mode. '
                      'Sign in to sync settings and data across devices.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Button(
          label: 'Sign in',
          icon: LucideIcons.log_in,
          variant: ButtonVariant.primary,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
