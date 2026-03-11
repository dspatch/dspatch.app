import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A sidebar navigation item with icon, label, active state, and collapse mode.
class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  /// When true, only the icon is shown with a tooltip.
  final bool isCollapsed;

  /// Optional trailing widget (e.g. a badge).
  final Widget? trailing;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
    this.isCollapsed = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDisabled
        ? AppColors.muted
        : isActive
        ? AppColors.primary
        : AppColors.mutedForeground;

    Widget item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: isActive ? AppColors.accentDim : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: AppColors.surfaceHover,
          onTap: isDisabled ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: isCollapsed
                  ? Row(children: [Icon(icon, size: 18, color: color)])
                  : Row(
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: isActive
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: item);
    }
    return item;
  }
}
