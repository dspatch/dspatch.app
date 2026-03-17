// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// A single result item displayed in the [UnifiedSearchBar] dropdown.
class SearchResultItem {
  const SearchResultItem({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.isHub = false,
    this.hubAuthor,
    this.hubLikes,
    this.hubVerified = false,
    this.onDownload,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isHub;
  final String? hubAuthor;
  final int? hubLikes;
  final bool hubVerified;
  final VoidCallback? onDownload;
}

/// A search bar with a dropdown overlay that displays local and hub results.
///
/// The parent is responsible for filtering local results and fetching hub
/// results; this widget only handles the input debouncing and overlay
/// presentation.
class UnifiedSearchBar extends StatefulWidget {
  const UnifiedSearchBar({
    super.key,
    required this.placeholder,
    required this.onQueryChanged,
    this.localResults = const [],
    this.hubResults = const [],
    this.isLoadingHub = false,
  });

  /// Placeholder text for the search input.
  final String placeholder;

  /// Called when the debounced query changes.
  final ValueChanged<String> onQueryChanged;

  /// Local results, already filtered by the parent.
  final List<SearchResultItem> localResults;

  /// Hub results, fetched by the parent.
  final List<SearchResultItem> hubResults;

  /// Whether hub results are currently loading.
  final bool isLoadingHub;

  @override
  State<UnifiedSearchBar> createState() => _UnifiedSearchBarState();
}

class _UnifiedSearchBarState extends State<UnifiedSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant UnifiedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Focus
  // ---------------------------------------------------------------------------

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        _showOverlay();
      }
    } else {
      // Delay removal so that tap events on overlay items can fire first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Input handling
  // ---------------------------------------------------------------------------

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      _removeOverlay();
      widget.onQueryChanged('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQueryChanged(value);
      _showOverlay();
    });
  }

  void _clearSearch() {
    _controller.clear();
    _removeOverlay();
    widget.onQueryChanged('');
  }

  // ---------------------------------------------------------------------------
  // Overlay
  // ---------------------------------------------------------------------------

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, renderBox.size.height + 4),
        child: Material(
          color: Colors.transparent,
          child: _DropdownContent(
            localResults: widget.localResults,
            hubResults: widget.hubResults,
            isLoadingHub: widget.isLoadingHub,
            hasQuery: _controller.text.isNotEmpty,
            onItemTap: _clearSearch,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Input(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder,
        prefix: const Icon(
          LucideIcons.search,
          size: 16,
          color: AppColors.mutedForeground,
        ),
        suffix: _controller.text.isNotEmpty
            ? GestureDetector(
                onTap: _clearSearch,
                child: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              )
            : null,
        onChanged: _onChanged,
      ),
    );
  }
}

// =============================================================================
// Dropdown content (extracted for readability)
// =============================================================================

class _DropdownContent extends StatelessWidget {
  const _DropdownContent({
    required this.localResults,
    required this.hubResults,
    required this.isLoadingHub,
    required this.hasQuery,
    required this.onItemTap,
  });

  final List<SearchResultItem> localResults;
  final List<SearchResultItem> hubResults;
  final bool isLoadingHub;
  final bool hasQuery;
  final VoidCallback onItemTap;

  @override
  Widget build(BuildContext context) {
    final hasLocal = localResults.isNotEmpty;
    final hasHub = hubResults.isNotEmpty;
    final showHubSection = hasHub || isLoadingHub;
    final showEmpty = hasQuery && !hasLocal && !hasHub && !isLoadingHub;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Local section --
              if (hasLocal) ...[
                _sectionLabel('Local'),
                for (final item in localResults) _buildLocalItem(item),
              ],

              // -- Hub section --
              if (showHubSection) ...[
                _sectionLabel('Community Hub'),
                if (isLoadingHub && !hasHub)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.md),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                for (final item in hubResults) _buildHubItem(item),
              ],

              // -- Empty state --
              if (showEmpty)
                const Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildLocalItem(SearchResultItem item) {
    return InkWell(
      onTap: () {
        onItemTap();
        item.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                  if (item.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
          ],
        ),
      ),
    );
  }

  Widget _buildHubItem(SearchResultItem item) {
    return InkWell(
      onTap: () {
        if (item.onDownload != null) {
          item.onDownload!();
        } else {
          onItemTap();
          item.onTap();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            // Name
            Flexible(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Verified badge
            if (item.hubVerified) ...[
              const SizedBox(width: Spacing.xs),
              const Icon(
                LucideIcons.badge_check,
                size: 14,
                color: AppColors.primary,
              ),
            ],

            // Author
            if (item.hubAuthor != null) ...[
              const SizedBox(width: Spacing.sm),
              Text(
                'by ${item.hubAuthor}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],

            // Likes
            if (item.hubLikes != null) ...[
              const SizedBox(width: Spacing.sm),
              const Icon(
                Icons.favorite,
                size: 12,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 2),
              Text(
                '${item.hubLikes}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],

            // Download button
            if (item.onDownload != null) ...[
              const SizedBox(width: Spacing.sm),
              Button(
                size: ButtonSize.xs,
                variant: ButtonVariant.outline,
                icon: LucideIcons.download,
                label: 'Download',
                onPressed: item.onDownload,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
