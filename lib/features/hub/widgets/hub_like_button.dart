// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/auth_gate.dart';
import '../../../di/providers.dart';
import '../hub_providers.dart';

/// A heart-shaped like/unlike button with optimistic toggle and star count.
class HubLikeButton extends ConsumerStatefulWidget {
  const HubLikeButton({
    super.key,
    required this.slug,
    required this.targetType,
    required this.initialStars,
    required this.initialLiked,
  });

  final String slug;

  /// Either `'agent'` or `'workspace'`.
  final String targetType;
  final int initialStars;
  final bool initialLiked;

  @override
  ConsumerState<HubLikeButton> createState() => _HubLikeButtonState();
}

class _HubLikeButtonState extends ConsumerState<HubLikeButton> {
  late int _stars = widget.initialStars;
  bool _loading = false;

  bool get _liked {
    final provider = widget.targetType == 'agent'
        ? likedAgentSlugsProvider
        : likedWorkspaceSlugsProvider;
    return ref.watch(provider).contains(widget.slug);
  }

  void _setLiked(bool value) {
    final provider = widget.targetType == 'agent'
        ? likedAgentSlugsProvider
        : likedWorkspaceSlugsProvider;
    final notifier = ref.read(provider.notifier);
    final current = Set<String>.of(notifier.state);
    if (value) {
      current.add(widget.slug);
    } else {
      current.remove(widget.slug);
    }
    notifier.state = current;
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (!await requireAuth(context, ref)) return;

    // Optimistic update
    final prevLiked = _liked;
    final prevStars = _stars;
    _setLiked(!prevLiked);
    setState(() {
      _stars += _liked ? 1 : -1;
    });

    setState(() => _loading = true);
    try {
      final client = ref.read(engineClientProvider);
      if (widget.targetType == 'agent') {
        await client.hubVoteAgent(slug: widget.slug, like: _liked);
      } else {
        await client.hubVoteWorkspace(slug: widget.slug, like: _liked);
      }
    } catch (e) {
      // Revert optimistic update
      if (mounted) {
        _setLiked(prevLiked);
        setState(() {
          _stars = prevStars;
        });
        toast('Failed to update vote', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _liked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: _liked
                  ? Colors.red
                  : AppColors.mutedForeground.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              '$_stars',
              style: TextStyle(
                fontSize: 12,
                color: _liked
                    ? AppColors.foreground
                    : AppColors.mutedForeground.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
