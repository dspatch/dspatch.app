// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dspatch_ui/dspatch_ui.dart';

import '../../core/extensions/string_ext.dart';
import '../../di/providers.dart';

/// App-specific breadcrumb wrapper that resolves routes to [BreadcrumbItem]s.
class AppBreadcrumbs extends ConsumerWidget {
  final String currentPath;

  const AppBreadcrumbs({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Breadcrumb(items: _resolveCrumbs(context, ref, currentPath));
  }

  static List<BreadcrumbItem> _resolveCrumbs(
      BuildContext context, WidgetRef ref, String path) {
    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;

    if (normalized == '/sessions') {
      return [const BreadcrumbItem(label: 'Sessions')];
    }

    if (normalized == '/sessions/new') {
      return [
        BreadcrumbItem(
            label: 'Sessions', onTap: () => context.go('/sessions')),
        const BreadcrumbItem(label: 'New Session'),
      ];
    }

    final sessionMatch =
        RegExp(r'^/sessions/(.+)$').firstMatch(normalized);
    if (sessionMatch != null) {
      return [
        BreadcrumbItem(
            label: 'Sessions', onTap: () => context.go('/sessions')),
        BreadcrumbItem(label: 'Session', subtitle: sessionMatch.group(1)),
      ];
    }

    if (normalized == '/inquiries') {
      return [const BreadcrumbItem(label: 'Inquiries')];
    }

    final inquiryMatch =
        RegExp(r'^/inquiries/(.+)$').firstMatch(normalized);
    if (inquiryMatch != null) {
      return [
        BreadcrumbItem(
            label: 'Inquiries', onTap: () => context.go('/inquiries')),
        BreadcrumbItem(label: 'Inquiry', subtitle: inquiryMatch.group(1)),
      ];
    }

    if (normalized == '/providers') {
      return [const BreadcrumbItem(label: 'Providers')];
    }

    if (normalized == '/providers/new') {
      return [
        BreadcrumbItem(
            label: 'Providers', onTap: () => context.go('/providers')),
        const BreadcrumbItem(label: 'New'),
      ];
    }

    final providerEditMatch =
        RegExp(r'^/providers/(.+)/edit$').firstMatch(normalized);
    if (providerEditMatch != null) {
      return [
        BreadcrumbItem(
            label: 'Providers', onTap: () => context.go('/providers')),
        BreadcrumbItem(label: 'Edit', subtitle: providerEditMatch.group(1)),
      ];
    }

    if (normalized == '/agent-providers') {
      return [const BreadcrumbItem(label: 'Agents')];
    }

    if (normalized == '/agent-providers/new') {
      return [
        BreadcrumbItem(
            label: 'Agents',
            onTap: () => context.go('/agent-providers')),
        const BreadcrumbItem(label: 'New'),
      ];
    }

    final templateEditMatch =
        RegExp(r'^/agent-providers/(.+)/edit$').firstMatch(normalized);
    if (templateEditMatch != null) {
      return [
        BreadcrumbItem(
            label: 'Agents',
            onTap: () => context.go('/agent-providers')),
        BreadcrumbItem(
            label: 'Edit', subtitle: templateEditMatch.group(1)),
      ];
    }

    if (normalized == '/workspaces') {
      return [const BreadcrumbItem(label: 'Workspaces')];
    }

    if (normalized == '/workspaces/new') {
      return [
        BreadcrumbItem(
            label: 'Workspaces', onTap: () => context.go('/workspaces')),
        const BreadcrumbItem(label: 'New Workspace'),
      ];
    }

    final workspaceMatch =
        RegExp(r'^/workspaces/(.+)$').firstMatch(normalized);
    if (workspaceMatch != null) {
      final workspaceId = workspaceMatch.group(1)!;
      final workspace =
          ref.watch(workspaceProvider(workspaceId)).valueOrNull;
      final displayName = workspace?.name ?? 'Workspace';
      return [
        BreadcrumbItem(
            label: 'Workspaces', onTap: () => context.go('/workspaces')),
        BreadcrumbItem(
          label: displayName,
          subtitle: workspaceId.shortIdForLog,
        ),
      ];
    }

    if (normalized == '/engine') {
      return [const BreadcrumbItem(label: 'Engine')];
    }

    if (normalized == '/settings') {
      return [const BreadcrumbItem(label: 'Settings')];
    }

    if (normalized == '/settings/api-keys') {
      return [
        BreadcrumbItem(
            label: 'Settings', onTap: () => context.go('/settings')),
        const BreadcrumbItem(label: 'API Keys'),
      ];
    }

    if (normalized == '/settings/notifications') {
      return [
        BreadcrumbItem(
            label: 'Settings', onTap: () => context.go('/settings')),
        const BreadcrumbItem(label: 'Notifications'),
      ];
    }

    final segments = normalized.split('/').where((s) => s.isNotEmpty);
    if (segments.isNotEmpty) {
      return [
        BreadcrumbItem(
          label:
              segments.last[0].toUpperCase() + segments.last.substring(1),
        ),
      ];
    }

    return [];
  }
}
