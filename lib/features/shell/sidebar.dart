// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../engine_client/models/auth_state.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart' hide DropdownMenuItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../core/utils/platform_info.dart';
import '../../di/providers.dart';
import '../hub/hub_providers.dart';


class AppSidebar extends ConsumerWidget {
  final String currentPath;
  final bool isDrawer;

  const AppSidebar({
    super.key,
    required this.currentPath,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = SidebarState.of(context)?.collapsed ?? false;
    final authState = ref.watch(authStateProvider).valueOrNull;
    ref.watch(loadUserVotesProvider);
    final workspaces = ref.watch(workspacesProvider).valueOrNull ?? [];
    final recentWorkspaces = workspaces.take(3).toList();

    final children = <Widget>[
      SidebarHeader(
        padding: const EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.lg,
          bottom: Spacing.xs,
        ),
        child: Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'd'),
                  const TextSpan(
                    text: ':',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  if (!collapsed) const TextSpan(text: 'spatch'),
                ],
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            if (!collapsed)
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (_, snapshot) {
                  final version = snapshot.data?.version;
                  if (version == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: Spacing.sm, top: 6),
                    child: Text(
                      'v$version',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                        height: 1,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      const SidebarSeparator(),
      SidebarContent(
        children: [
          SidebarGroup(
            children: [
              _WorkspacesNavItem(
                currentPath: currentPath,
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/workspaces'),
              ),
              _InquiriesNavItem(
                currentPath: currentPath,
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/inquiries'),
              ),
              NavItem(
                icon: LucideIcons.cpu,
                label: 'Agents',
                isActive: currentPath.startsWith('/agent-providers'),
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/agent-providers'),
              ),
              if (PlatformInfo.isDesktop)
                NavItem(
                  icon: LucideIcons.server,
                  label: 'Engine',
                  isActive: currentPath.startsWith('/engine'),
                  isCollapsed: collapsed,
                  onTap: () => _navigate(context, '/engine'),
                ),
            ],
          ),
          if (recentWorkspaces.isNotEmpty)
            SidebarGroup(
              label: 'Recent',
              children: [
                for (final ws in recentWorkspaces)
                  NavItem(
                    icon: LucideIcons.folder,
                    label: ws.name,
                    isActive: currentPath == '/workspaces/${ws.id}',
                    isCollapsed: collapsed,
                    trailing: null,
                    onTap: () => _navigate(context, '/workspaces/${ws.id}'),
                  ),
              ],
            ),
          SidebarGroup(
            label: 'Quick Actions',
            children: [
              NavItem(
                icon: LucideIcons.circle_plus,
                label: 'New Workspace',
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/workspaces/new'),
              ),
              NavItem(
                icon: LucideIcons.book_plus,
                label: 'New Template',
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/agent-providers/new'),
              ),
              NavItem(
                icon: LucideIcons.key,
                label: 'API Keys',
                isActive: currentPath == '/settings/api-keys',
                isCollapsed: collapsed,
                onTap: () => _navigate(context, '/settings/api-keys'),
              ),
            ],
          ),
        ],
      ),
      Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: _UserMenuTile(
          authState: authState,
          isCollapsed: collapsed,
          isDrawer: isDrawer,
        ),
      ),
    ];

    if (isDrawer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Sidebar(width: kSidebarWidth, children: children);
  }

  void _navigate(BuildContext context, String path) {
    context.go(path);
    if (isDrawer) Navigator.of(context).pop();
  }
}

class _UserMenuTile extends ConsumerWidget {
  final AuthState? authState;
  final bool isCollapsed;
  final bool isDrawer;

  const _UserMenuTile({
    required this.authState,
    required this.isCollapsed,
    required this.isDrawer,
  });

  bool get _isSignedIn =>
      authState != null && authState!.mode == AuthMode.connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DspatchDropdownMenu(
      side: DropdownSide.top,
      align: DropdownAlign.start,
      width: 220,
      trigger: _buildTrigger(),
      children: _buildMenuItems(context, ref),
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
  ) {
    void navigate(String path) {
      context.go(path);
      if (isDrawer) Navigator.of(context).pop();
    }

    return [
      if (_isSignedIn) ...[
        DropdownMenuLabel(text: 'My Account'),
        const DropdownMenuSeparator(),
      ] else ...[
        DropdownMenuLabel(text: 'Guest Mode'),
        DropdownMenuItem(
          icon: LucideIcons.log_in,
          label: 'Sign in',
          onTap: () => ref.read(engineClientProvider).logout(),
        ),
        const DropdownMenuSeparator(),
      ],
      DropdownMenuItem(
        icon: LucideIcons.key,
        label: 'API Keys',
        onTap: () => navigate('/settings/api-keys'),
      ),
      DropdownMenuItem(
        icon: LucideIcons.bell,
        label: 'Notifications',
        onTap: () => navigate('/settings/notifications'),
      ),
      const DropdownMenuSeparator(),
      DropdownMenuItem(
        icon: LucideIcons.settings,
        label: 'All Settings',
        onTap: () => navigate('/settings'),
      ),
      if (_isSignedIn) ...[
        const DropdownMenuSeparator(),
        DropdownMenuItem(
          icon: LucideIcons.log_out,
          label: 'Log out',
          onTap: () => ref.read(engineClientProvider).logout(),
        ),
      ],
    ];
  }

  Widget _buildTrigger() {
    if (_isSignedIn) {
      return _buildAccountTrigger();
    }
    return _buildGuestTrigger();
  }

  Widget _buildGuestTrigger() {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: isCollapsed
                  ? Row(children: [
                      Icon(LucideIcons.user,
                          size: 18, color: AppColors.mutedForeground),
                    ])
                  : Row(children: [
                      Icon(LucideIcons.user,
                          size: 18, color: AppColors.mutedForeground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Guest',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevrons_up_down,
                          size: 16, color: AppColors.muted),
                    ]),
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return DspatchTooltip(message: 'Guest', child: tile);
    }
    return tile;
  }

  Widget _buildAccountTrigger() {
    final initial = (authState!.username ?? authState!.email ?? '?')
        .characters
        .first
        .toUpperCase();
    final username = authState!.username ?? 'User';
    final email = authState!.email;

    final avatar = DspatchAvatar(
      fallback: initial,
      size: 22,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
    );

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: isCollapsed
                  ? Row(children: [avatar])
                  : Row(
                      children: [
                        avatar,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (email != null)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevrons_up_down,
                            size: 16, color: AppColors.muted),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return DspatchTooltip(message: username, child: tile);
    }
    return tile;
  }
}

class _WorkspacesNavItem extends ConsumerWidget {
  const _WorkspacesNavItem({
    required this.currentPath,
    required this.isCollapsed,
    required this.onTap,
  });

  final String currentPath;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(globalPendingInquiryCountProvider).valueOrNull ?? 0;

    return NavItem(
      icon: LucideIcons.layout_grid,
      label: 'Workspaces',
      isActive: currentPath.startsWith('/workspaces'),
      isCollapsed: isCollapsed,
      trailing: count > 0
          ? DspatchBadge(
              label: '$count',
              variant: BadgeVariant.warning,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _InquiriesNavItem extends ConsumerWidget {
  const _InquiriesNavItem({
    required this.currentPath,
    required this.isCollapsed,
    required this.onTap,
  });

  final String currentPath;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(globalPendingInquiryCountProvider).valueOrNull ?? 0;

    return NavItem(
      icon: LucideIcons.circle_question_mark,
      label: 'Inquiries',
      isActive: currentPath.startsWith('/inquiries'),
      isCollapsed: isCollapsed,
      trailing: count > 0
          ? DspatchBadge(
              label: '$count',
              variant: BadgeVariant.warning,
            )
          : null,
      onTap: onTap,
    );
  }
}
