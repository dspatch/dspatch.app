// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/platform_info.dart';
import '../../../di/providers.dart';

/// Prominent Docker error/install banner pinned above scrollable content.
///
/// Shows an [AlertBanner] when Docker is not running or fails to connect.
/// Hidden when Docker is running normally.
class DockerErrorBanner extends ConsumerWidget {
  const DockerErrorBanner({super.key});

  static const _installUrls = {
    'macos': 'https://docs.docker.com/desktop/install/mac-install/',
    'windows': 'https://docs.docker.com/desktop/install/windows-install/',
    'linux': 'https://docs.docker.com/engine/install/',
  };

  static const _troubleshootUrl =
      'https://docs.docker.com/config/daemon/troubleshoot/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dockerStatusProvider);

    return status.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: AlertBanner(
          label: 'Failed to connect to Docker',
          buttonLabel: 'Troubleshoot',
          variant: AlertBannerVariant.destructive,
          onPressed: () => launchUrl(Uri.parse(_troubleshootUrl)),
        ),
      ),
      data: (s) {
        if (s.isRunning) return const SizedBox.shrink();
        if (s.isInstalled) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: AlertBanner(
              label: 'Docker is not running. Start Docker Desktop to continue.',
              buttonLabel: 'Troubleshoot',
              variant: AlertBannerVariant.warning,
              onPressed: () => launchUrl(Uri.parse(_troubleshootUrl)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: AlertBanner(
            label: _installLabel,
            buttonLabel: 'Install Docker',
            variant: AlertBannerVariant.warning,
            onPressed: _launchInstallUrl,
          ),
        );
      },
    );
  }

  String get _installLabel {
    if (PlatformInfo.isMacOS) return 'Install Docker Desktop for macOS';
    if (PlatformInfo.isWindows) return 'Install Docker Desktop for Windows';
    return 'Install Docker Engine for Linux';
  }

  void _launchInstallUrl() {
    final key = PlatformInfo.isMacOS
        ? 'macos'
        : PlatformInfo.isWindows
            ? 'windows'
            : 'linux';
    launchUrl(Uri.parse(_installUrls[key]!));
  }
}
