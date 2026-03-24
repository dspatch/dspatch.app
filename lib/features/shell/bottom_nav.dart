// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/platform_info.dart';
import '../../di/providers.dart';

/// Single source of truth for mobile bottom navigation items.
/// Each entry maps a route prefix to its icon and label.
List<({String path, IconData icon, String label})> get _navItems => [
  (path: '/workspaces', icon: LucideIcons.layout_grid, label: 'Workspaces'),
  (path: '/agent-providers', icon: LucideIcons.bot, label: 'Templates'),
  (path: '/devices', icon: LucideIcons.monitor_smartphone, label: 'Devices'),
  if (PlatformInfo.isDesktop)
    (path: '/engine', icon: LucideIcons.server, label: 'Engine'),
  (path: '/settings', icon: LucideIcons.settings, label: 'Settings'),
];

const _defaultIndex = 0; // workspaces

class BottomNav extends ConsumerWidget {
  final String currentPath;

  const BottomNav({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        ref.watch(globalPendingInquiryCountProvider).valueOrNull ?? 0;
    final items = _navItems;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _indexFromPath(currentPath, items),
        onTap: (index) => context.go(items[index].path),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: item.path == '/workspaces' && pendingCount > 0
                  ? Badge.count(
                      count: pendingCount,
                      child: Icon(item.icon),
                    )
                  : Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  int _indexFromPath(
    String path,
    List<({String path, IconData icon, String label})> items,
  ) {
    for (var i = 0; i < items.length; i++) {
      if (path.startsWith(items[i].path)) return i;
    }
    return _defaultIndex;
  }
}
