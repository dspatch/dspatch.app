import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'copy_button.dart';

/// Toast type for [Sonner].
enum ToastType { normal, success, error, info, warning, loading }

/// Data describing a single toast.
class ToastData {
  ToastData({
    required this.id,
    required this.message,
    this.description,
    this.type = ToastType.normal,
    this.duration = const Duration(seconds: 4),
    this.action,
    this.actionLabel,
    this.onDismiss,
  });

  final String id;
  final String message;
  final String? description;
  final ToastType type;
  final Duration duration;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? onDismiss;
}

/// Global toast controller. Use [Toaster] widget + [toast] function.
class SonnerController extends ChangeNotifier {
  final List<ToastData> _toasts = [];
  List<ToastData> get toasts => List.unmodifiable(_toasts);

  int _idCounter = 0;

  String add(ToastData data) {
    _toasts.add(data);
    notifyListeners();
    return data.id;
  }

  void remove(String id) {
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  String nextId() => 'toast_${_idCounter++}';
}

/// The global controller instance.
final SonnerController _globalController = SonnerController();

/// Show a toast. Place a [Toaster] widget in your widget tree first.
///
/// ```dart
/// toast('Event has been created');
/// toast('Error occurred', type: ToastType.error);
/// toast('Saved', type: ToastType.success, description: 'Your changes were saved.');
/// ```
String toast(
  String message, {
  String? description,
  ToastType type = ToastType.normal,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? action,
  String? actionLabel,
  VoidCallback? onDismiss,
}) {
  final id = _globalController.nextId();
  _globalController.add(ToastData(
    id: id,
    message: message,
    description: description,
    type: type,
    duration: duration,
    action: action,
    actionLabel: actionLabel,
    onDismiss: onDismiss,
  ));
  return id;
}

/// Dismiss a toast by id.
void dismissToast(String id) {
  _globalController.remove(id);
}

/// Position of the toast stack.
enum ToasterPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// A widget that displays stacking toasts. Place in your widget tree
/// (typically in your root layout via [Overlay] or [Stack]).
///
/// ```dart
/// Stack(
///   children: [
///     Scaffold(...),
///     const Toaster(),
///   ],
/// )
/// ```
class Toaster extends StatefulWidget {
  const Toaster({
    super.key,
    this.position = ToasterPosition.bottomRight,
    this.maxVisible = 3,
  });

  /// Where toasts appear.
  final ToasterPosition position;

  /// Max visible toasts at once.
  final int maxVisible;

  @override
  State<Toaster> createState() => _ToasterState();
}

class _ToasterState extends State<Toaster> {
  @override
  void initState() {
    super.initState();
    _globalController.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _globalController.removeListener(_onUpdate);
    super.dispose();
  }

  Alignment _getAlignment() {
    return switch (widget.position) {
      ToasterPosition.topLeft => Alignment.topLeft,
      ToasterPosition.topCenter => Alignment.topCenter,
      ToasterPosition.topRight => Alignment.topRight,
      ToasterPosition.bottomLeft => Alignment.bottomLeft,
      ToasterPosition.bottomCenter => Alignment.bottomCenter,
      ToasterPosition.bottomRight => Alignment.bottomRight,
    };
  }

  bool get _isTop => switch (widget.position) {
        ToasterPosition.topLeft ||
        ToasterPosition.topCenter ||
        ToasterPosition.topRight =>
          true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final toasts = _globalController.toasts;
    final visible =
        toasts.length > widget.maxVisible
            ? toasts.sublist(toasts.length - widget.maxVisible)
            : toasts;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: visible.isEmpty,
        child: Align(
          alignment: _getAlignment(),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isTop)
                  for (final t in visible) _ToastWidget(key: ValueKey(t.id), data: t)
                else
                  for (final t in visible.reversed)
                    _ToastWidget(key: ValueKey(t.id), data: t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({super.key, required this.data});

  final ToastData data;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    if (widget.data.type != ToastType.loading) {
      _timer = Timer(widget.data.duration, _dismiss);
    }
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.data.onDismiss?.call();
        _globalController.remove(widget.data.id);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  IconData? _getIcon() {
    return switch (widget.data.type) {
      ToastType.success => LucideIcons.circle_check,
      ToastType.error => LucideIcons.circle_alert,
      ToastType.info => LucideIcons.info,
      ToastType.warning => LucideIcons.triangle_alert,
      ToastType.loading => LucideIcons.hourglass,
      ToastType.normal => null,
    };
  }

  Color _getIconColor() {
    return switch (widget.data.type) {
      ToastType.success => AppColors.success,
      ToastType.error => AppColors.error,
      ToastType.info => AppColors.info,
      ToastType.warning => AppColors.warning,
      ToastType.loading => AppColors.mutedForeground,
      ToastType.normal => AppColors.foreground,
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: 360,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: _getIconColor()),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.data.message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (widget.data.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.data.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.data.action != null &&
                      widget.data.actionLabel != null) ...[
                    const SizedBox(width: Spacing.sm),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          widget.data.action!();
                          _dismiss();
                        },
                        child: Text(
                          widget.data.actionLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: Spacing.sm),
                  CopyButton(
                    textToCopy: [
                      widget.data.message,
                      if (widget.data.description != null)
                        widget.data.description!,
                    ].join('\n'),
                    iconSize: 12,
                    showTooltip: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
