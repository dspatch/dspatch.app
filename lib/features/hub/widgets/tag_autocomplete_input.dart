// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';

/// Autocomplete tag input with fuzzy search, popular-tag preloading, and
/// inline tag creation for a single [category].
///
/// Selected tags are rendered as dismissible [DspatchBadge]s above the text
/// field. Suggestions are loaded from the hub API (debounced 300 ms).
class TagAutocompleteInput extends ConsumerStatefulWidget {
  const TagAutocompleteInput({
    super.key,
    required this.category,
    required this.label,
    required this.selectedTags,
    required this.onChanged,
  });

  /// Tag category — e.g. `'general'`, `'model'`, `'framework'`.
  final String category;

  /// Field label text.
  final String label;

  /// Currently selected tags.
  final Set<HubTagRef> selectedTags;

  /// Called when the selection changes.
  final ValueChanged<Set<HubTagRef>> onChanged;

  @override
  ConsumerState<TagAutocompleteInput> createState() =>
      _TagAutocompleteInputState();
}

class _TagAutocompleteInputState extends ConsumerState<TagAutocompleteInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<HubTagRef> _suggestions = [];
  bool _showDropdown = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Slug / display-name helpers
  // ---------------------------------------------------------------------------

  /// Normalise an arbitrary string into a URL-safe slug.
  static String _normalizeSlug(String raw) {
    var slug = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    slug = slug.replaceAll(RegExp(r'-{2,}'), '-');
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    return slug;
  }

  /// Derive a display name from a slug by capitalising each word.
  static String _displayNameFromSlug(String slug) {
    return slug
        .split('-')
        .where((s) => s.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _controller.text.isEmpty) {
      _loadPopular();
    }
    if (!_focusNode.hasFocus) {
      // Delay hiding so tap events on the dropdown register first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showDropdown = false);
        }
      });
    }
  }

  Future<void> _loadPopular() async {
    setState(() => _loading = true);
    try {
      final sdk = ref.read(sdkProvider);
      final tags = await sdk.hubPopularTags(
        category: widget.category,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = tags
            .map((t) => HubTagRef(
                  slug: t.slug,
                  displayName: t.displayName,
                  category: t.category,
                ))
            .toList();
        _showDropdown = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showDropdown = true;
        _loading = false;
      });
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _loadPopular();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final sdk = ref.read(sdkProvider);
        final tags = await sdk.hubSearchTags(
          query: value.trim(),
          category: widget.category,
          limit: 20,
        );
        if (!mounted) return;
        setState(() {
          _suggestions = tags
              .map((t) => HubTagRef(
                    slug: t.slug,
                    displayName: t.displayName,
                    category: t.category,
                  ))
              .toList();
          _showDropdown = true;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _showDropdown = true;
          _loading = false;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _selectTag(HubTagRef tagRef) {
    if (widget.selectedTags.any((t) => t.slug == tagRef.slug)) return;
    final updated = {...widget.selectedTags, tagRef};
    widget.onChanged(updated);
    _controller.clear();
    setState(() => _showDropdown = false);
  }

  void _removeTag(HubTagRef tagRef) {
    final updated = {...widget.selectedTags}
      ..removeWhere((t) => t.slug == tagRef.slug);
    widget.onChanged(updated);
  }

  Future<void> _createNewTag(String slug) async {
    final displayName = _displayNameFromSlug(slug);

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Create new tag',
      description:
          "Tag '$slug' doesn't exist yet. Create it as a ${widget.category} tag?",
      confirmLabel: 'Create',
      confirmVariant: ButtonVariant.primary,
    );

    if (!confirmed || !mounted) return;

    _selectTag(HubTagRef(
      slug: slug,
      displayName: displayName,
      category: widget.category,
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final normalizedSlug = _normalizeSlug(query);
    final hasExactMatch =
        _suggestions.any((t) => t.slug == normalizedSlug);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected tags -------------------------------------------------------
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: widget.selectedTags.map((tag) {
              return GestureDetector(
                onTap: () => _removeTag(tag),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DspatchBadge(
                        label: tag.displayName,
                        variant: BadgeVariant.secondary,
                        icon: LucideIcons.x,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.sm),
        ],

        // Input field ---------------------------------------------------------
        Field(
          label: widget.label,
          child: Input(
            controller: _controller,
            focusNode: _focusNode,
            placeholder: 'Search tags...',
            onChanged: _onTextChanged,
            suffix: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ),

        // Dropdown suggestions ------------------------------------------------
        if (_showDropdown && (_suggestions.isNotEmpty || normalizedSlug.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: Spacing.xs),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                ..._suggestions
                    .where((t) => !widget.selectedTags
                        .any((sel) => sel.slug == t.slug))
                    .map((tag) => ListTile(
                          dense: true,
                          title: Text(
                            tag.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                          onTap: () => _selectTag(HubTagRef(
                            slug: tag.slug,
                            displayName: tag.displayName,
                            category: tag.category,
                          )),
                        )),

                // "Create new" option -----------------------------------------
                if (normalizedSlug.isNotEmpty && !hasExactMatch)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                    title: Text(
                      "Create '$normalizedSlug'",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foreground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    onTap: () => _createNewTag(normalizedSlug),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
