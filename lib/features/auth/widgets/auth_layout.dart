// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/platform_info.dart';
import '../../../shared/services/title_bar_service.dart';
import 'engine_status_button.dart';

/// Shared layout for all authentication screens.
///
/// Renders centered d:spatch branding, an optional [DspatchStepper]
/// for multi-step registration, and a [child] content slot.
class AuthLayout extends StatefulWidget {
  const AuthLayout({
    super.key,
    this.stepperStep,
    this.stepperTotal,
    required this.child,
  });

  /// Current step (1-based) for the registration stepper. Omit for login.
  final int? stepperStep;

  /// Total steps for the registration stepper. Omit for login.
  final int? stepperTotal;

  /// Screen content (card, form, etc.).
  final Widget child;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  @override
  void initState() {
    super.initState();
    TitleBarService.setColor(AppColors.background);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.xxl,
                      ),
                      child: SizedBox(
                        width: 420,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Agent Orchestration Platform',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: Spacing.xl),

                            // Registration stepper
                            if (widget.stepperStep != null &&
                                widget.stepperTotal != null) ...[
                              DspatchStepper(
                                totalSteps: widget.stepperTotal!,
                                currentStep: widget.stepperStep!,
                              ),
                              const SizedBox(height: Spacing.lg),
                            ],

                            // Content
                            widget.child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Engine status button — bottom-left corner (desktop only)
          if (PlatformInfo.isDesktop)
            const Positioned(
              left: Spacing.md,
              bottom: Spacing.md,
              child: EngineStatusButton(),
            ),
        ],
      ),
    );
  }
}
