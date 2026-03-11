import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import 'badge.dart';

/// Maps a status string to the appropriate [BadgeVariant].
BadgeVariant badgeVariantForStatus(String status) {
  return switch (status) {
    'passed' => BadgeVariant.success,
    'failed' => BadgeVariant.destructive,
    'running' => BadgeVariant.info,
    'pending' => BadgeVariant.secondary,
    'error' => BadgeVariant.warning,
    'cancelled' => BadgeVariant.secondary,
    _ => BadgeVariant.secondary,
  };
}

/// Maps a status string to a representative [IconData].
IconData iconForStatus(String status) {
  return switch (status) {
    'passed' => LucideIcons.circle_check,
    'failed' => LucideIcons.circle_x,
    'running' => LucideIcons.circle_play,
    'pending' => LucideIcons.circle,
    'error' => LucideIcons.circle_alert,
    'cancelled' => LucideIcons.circle_stop,
    'skipped' => LucideIcons.skip_forward,
    _ => LucideIcons.circle_question_mark,
  };
}

/// Maps a status string to a semantic [Color].
Color colorForStatus(String status) {
  return switch (status) {
    'passed' => AppColors.success,
    'failed' => AppColors.destructive,
    'running' => AppColors.info,
    'pending' => AppColors.mutedForeground,
    'error' => AppColors.warning,
    'cancelled' => AppColors.mutedForeground,
    'skipped' => AppColors.mutedForeground,
    _ => AppColors.mutedForeground,
  };
}
