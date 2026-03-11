// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';

/// Single source of truth for mobile bottom navigation items.
/// Each entry maps a route prefix to its icon and label.
const _navItems = [
  (path: '/workspaces', icon: LucideIcons.layout_grid, label: 'Workspaces'),
  (path: '/agent-providers', icon: LucideIcons.bot, label: 'Templates'),
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _indexFromPath(currentPath),
        onTap: (index) => context.go(_navItems[index].path),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          // Workspaces
          BottomNavigationBarItem(
            icon: pendingCount > 0
                ? Badge.count(
                    count: pendingCount,
                    child: Icon(_navItems[0].icon),
                  )
                : Icon(_navItems[0].icon),
            label: _navItems[0].label,
          ),
          // Templates
          BottomNavigationBarItem(
            icon: Icon(_navItems[1].icon),
            label: _navItems[1].label,
          ),
          // Engine
          BottomNavigationBarItem(
            icon: Icon(_navItems[2].icon),
            label: _navItems[2].label,
          ),
          // Settings
          BottomNavigationBarItem(
            icon: Icon(_navItems[3].icon),
            label: _navItems[3].label,
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    for (var i = 0; i < _navItems.length; i++) {
      if (path.startsWith(_navItems[i].path)) return i;
    }
    return _defaultIndex;
  }
}
