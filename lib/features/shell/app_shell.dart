// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/services/title_bar_service.dart';
import 'bottom_nav.dart';
import 'breadcrumbs.dart';
import 'sidebar.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _sidebarKey = GlobalKey<SidebarProviderState>();
  final _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    TitleBarService.setColor(AppColors.card);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kSidebarBreakpoint;

        if (isMobile) {
          return _buildMobileLayout(currentPath);
        }
        return _buildDesktopLayout(currentPath);
      },
    );
  }

  Widget _buildDesktopLayout(String currentPath) {
    return Scaffold(
      body: SidebarProvider(
        key: _sidebarKey,
        child: Row(
          children: [
            AppSidebar(currentPath: currentPath),
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    leading: Button(
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.icon,
                      icon: LucideIcons.panel_left,
                      onPressed: () => _sidebarKey.currentState?.toggle(),
                    ),
                    title: Expanded(
                      child: AppBreadcrumbs(currentPath: currentPath),
                    ),
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String currentPath) {
    return Scaffold(
      key: _mobileScaffoldKey,
      drawer: Drawer(
        backgroundColor: AppColors.card,
        width: kSidebarWidth,
        child: SafeArea(
          child: SidebarProvider(
            defaultCollapsed: false,
            child: AppSidebar(isDrawer: true, currentPath: currentPath),
          ),
        ),
      ),
      body: Column(
        children: [
          TopBar(
            leading: Button(
              variant: ButtonVariant.ghost,
              size: ButtonSize.icon,
              icon: LucideIcons.menu,
              onPressed: () =>
                  _mobileScaffoldKey.currentState?.openDrawer(),
            ),
            title: Expanded(
              child: AppBreadcrumbs(currentPath: currentPath),
            ),
          ),
          Expanded(child: widget.child),
          BottomNav(currentPath: currentPath),
        ],
      ),
    );
  }
}
