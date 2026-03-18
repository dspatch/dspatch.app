// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../engine_client/models/auth_token.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../di/providers.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authToken = ref.watch(authTokenProvider);
    final isConnected = authToken is BackendToken;
    final username = isConnected ? authToken.username : null;

    return ContentArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                _tile(
                  icon: LucideIcons.key,
                  title: 'API Keys',
                  description: 'Manage encrypted API keys for agent providers',
                  onTap: () => context.go('/settings/api-keys'),
                ),
                const SizedBox(height: Spacing.sm),
                _tile(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  description: 'Configure desktop notification alerts',
                  onTap: () => context.go('/settings/notifications'),
                ),
                const SizedBox(height: Spacing.xl),

                // Account section
                _tile(
                  icon: LucideIcons.user,
                  title: isConnected
                      ? (username ?? 'Account')
                      : 'Anonymous mode',
                  description: isConnected
                      ? 'Signed in \u2022 ${isConnected ? authToken.email : ''}'
                      : 'Local-only \u2022 no sync or multi-device',
                  onTap: () => context.go('/settings/account'),

                ),
                const SizedBox(height: Spacing.sm),
                _tile(
                  icon: LucideIcons.log_out,
                  title: isConnected ? 'Sign out' : 'Switch to sign-in',
                  description: isConnected
                      ? 'Sign out and return to login'
                      : 'Sign in to sync across devices',
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                ),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Spacer(),
                _AboutInfo(context: context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
    Widget? trailing,
    bool enabled = true,
  }) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: DspatchCard(
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? AppColors.mutedForeground
                    : AppColors.muted,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: enabled
                            ? AppColors.foreground
                            : AppColors.mutedForeground,
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
              ?trailing,
              if (enabled)
                const Icon(
                  LucideIcons.chevron_right,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutInfo extends StatelessWidget {
  const _AboutInfo({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        final versionString =
            'v$version${buildNumber.isNotEmpty ? '+$buildNumber' : ''}';

        return Column(
          children: [
            const SizedBox(height: Spacing.lg),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'd'),
                  const TextSpan(
                    text: ':',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  const TextSpan(text: 'spatch'),
                ],
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              versionString,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Agent Orchestration Platform',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _link('Website', () =>
                    launchUrl(Uri.parse('https://dspatch.dev'))),
                _dot(),
                _link('GitHub', () => launchUrl(
                    Uri.parse('https://github.com/dspatch/dspatch.app'))),
                _dot(),
                _link('Licenses', () => showLicensePage(
                  context: context,
                  applicationName: 'd:spatch',
                  applicationVersion: versionString,
                )),
                _dot(),
                _link('Feedback', () => launchUrl(
                    Uri.parse('https://github.com/dspatch/dspatch.app/issues'))),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '\u00b7',
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    );
  }

  static Widget _link(String label, VoidCallback onTap) {
    return Button(
      label: label,
      variant: ButtonVariant.link,
      size: ButtonSize.xs,
      onPressed: onTap,
    );
  }
}
