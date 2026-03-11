// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared layout for all SaaS authentication stub screens.
///
/// Renders centered branding, icon, title, description, a "Coming soon"
/// badge, optional [stubContent], and a "Back to app" button. All auth
/// stub screens delegate to this layout for DRY consistency.
class AuthStubLayout extends StatelessWidget {
  const AuthStubLayout({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.stubContent,
  });

  final String title;
  final String description;
  final IconData? icon;
  final Widget? stubContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // Icon
            if (icon != null) ...[
              Icon(icon, size: 32, color: AppColors.mutedForeground),
              const SizedBox(height: Spacing.md),
            ],

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // Description
            SizedBox(
              width: 320,
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Coming soon badge
            const DspatchBadge(
              label: 'Coming soon',
              variant: BadgeVariant.secondary,
            ),

            // Optional stub content
            if (stubContent != null) ...[
              const SizedBox(height: Spacing.xl),
              stubContent!,
            ],

            const SizedBox(height: Spacing.xl),

            // Back button
            Button(
              label: 'Back to app',
              variant: ButtonVariant.outline,
              onPressed: () => context.go('/sessions'),
            ),
          ],
        ),
      ),
    );
  }
}
