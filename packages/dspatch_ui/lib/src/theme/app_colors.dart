import 'package:flutter/material.dart';

/// Design tokens matching the d:spatch website globals.css.
/// Dark-only theme based on shadcn/ui conventions.
abstract final class AppColors {
  // Core surfaces
  static const background = Color(0xFF1E1E27);
  static const foreground = Color(0xFFE8E6E2);
  static const card = Color(0xFF252536);
  static const cardForeground = Color(0xFFE8E6E2);
  static const popover = Color(0xFF13131F);
  static const popoverForeground = Color(0xFFE8E6E2);

  // Primary (lime accent)
  static const primary = Color(0xFFC4EF42);
  static const primaryForeground = Color(0xFF13131F);

  // Secondary
  static const secondary = Color(0xFF252536);
  static const secondaryForeground = Color(0xFFB0AEC0);

  // Muted
  static const muted = Color(0xFF45435A);
  static const mutedForeground = Color(0xFF6B6A7A);

  // Accent (same as primary)
  static const accent = Color(0xFFC4EF42);
  static const accentForeground = Color(0xFF13131F);
  static const accentSoft = Color(0xFFD3F56F);
  static const accentDim = Color(0x12C4F042); // ~7% opacity
  static const accentGlow = Color(0x1FC4F042); // ~12% opacity
  static const accentMuted = Color(0xFF7A9B30); // desaturated/dimmed lime

  // Destructive
  static const destructive = Color(0xFFF7788F);
  static const destructiveForeground = Color(0xFFE8E6E2);

  // Borders & inputs
  static const border = Color(0xFF34344B);
  static const input = Color(0xFF34344B);
  static const ring = Color(0xFFC4EF42);

  // Extended palette
  static const bgDeep = Color(0xFF13131F);
  static const surfaceHover = Color(0xFF29293C);
  static const borderSubtle = Color(0xFF29293C);
  static const shimmer = Color(0xFF53516A);

  // Terminal / semantic status colors
  static const terminalGreen = Color(0xFF9DCE68);
  static const terminalBlue = Color(0xFF78A0F7);
  static const terminalAmber = Color(0xFFDFAF66);
  static const terminalRose = Color(0xFFF7788F);

  // Semantic aliases
  static const success = terminalGreen;
  static const info = terminalBlue;
  static const warning = terminalAmber;
  static const error = terminalRose;
}
