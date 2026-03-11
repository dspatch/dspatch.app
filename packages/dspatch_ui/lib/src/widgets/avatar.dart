import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A circular avatar with image and fallback initials, inspired by shadcn/ui Avatar.
///
/// ```dart
/// DspatchAvatar(imageUrl: 'https://example.com/photo.jpg', fallback: 'JD')
/// DspatchAvatar(fallback: 'AB', size: 48)
/// ```
class DspatchAvatar extends StatelessWidget {
  const DspatchAvatar({
    super.key,
    this.imageUrl,
    this.fallback,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// URL of the avatar image.
  final String? imageUrl;

  /// Fallback text (typically initials) shown when image is unavailable.
  final String? fallback;

  /// Diameter of the avatar.
  final double size;

  /// Override the background color (defaults to [AppColors.muted]).
  final Color? backgroundColor;

  /// Override the fallback text color (defaults to [AppColors.mutedForeground]).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.muted,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final fontSize = size * 0.38;
    return Center(
      child: Text(
        (fallback ?? '?').substring(0, (fallback?.length ?? 1).clamp(0, 2)),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? AppColors.mutedForeground,
          fontFamily: AppFonts.sans,
        ),
      ),
    );
  }
}
