// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
//
// Widget tests for the dspatch_ui component library.
//
// These tests verify that core UI components render correctly and expose the
// right widget structure — without requiring any app-level providers or
// platform services.

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in the minimum scaffold needed for widget tests:
/// MaterialApp + dark theme.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

// ---------------------------------------------------------------------------
// Button tests
// ---------------------------------------------------------------------------

void main() {
  group('Button', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        Button(label: 'Save', onPressed: () {}),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(_wrap(
        const Button(label: 'Save', loading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label remains visible alongside the spinner
      expect(find.text('Save'), findsOneWidget);
      // onPressed is disabled while loading
      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.onPressed, isNull);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const Button(label: 'Disabled'),
      ));
      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.onPressed, isNull);
    });

    testWidgets('calls onPressed callback on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        Button(label: 'Click me', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(Button));
      expect(tapped, isTrue);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        Button(
          label: 'Add',
          icon: LucideIcons.plus,
          onPressed: () {},
        ),
      ));
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('icon-only button renders without label', (tester) async {
      await tester.pumpWidget(_wrap(
        Button(
          size: ButtonSize.icon,
          icon: LucideIcons.x,
          onPressed: () {},
        ),
      ));
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('all ButtonVariant values render without error', (tester) async {
      for (final variant in ButtonVariant.values) {
        await tester.pumpWidget(_wrap(
          Button(
            label: variant.name,
            variant: variant,
            onPressed: () {},
          ),
        ));
        expect(find.text(variant.name), findsOneWidget,
            reason: 'ButtonVariant.${variant.name} should render its label');
      }
    });

    testWidgets('compact flag maps to sm size', (tester) async {
      await tester.pumpWidget(_wrap(
        // ignore: deprecated_member_use_from_same_package
        Button(label: 'Compact', compact: true, onPressed: () {}),
      ));
      expect(find.text('Compact'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DspatchBadge tests
  // ---------------------------------------------------------------------------

  group('DspatchBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const DspatchBadge(label: 'Active'),
      ));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const DspatchBadge(
          label: 'Error',
          variant: BadgeVariant.destructive,
          icon: LucideIcons.circle_alert,
        ),
      ));
      expect(find.byIcon(LucideIcons.circle_alert), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('renders without icon by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const DspatchBadge(label: 'Running'),
      ));
      // No Icon widget should be present when no icon is passed
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('all BadgeVariant values render without error', (tester) async {
      for (final variant in BadgeVariant.values) {
        await tester.pumpWidget(_wrap(
          DspatchBadge(label: variant.name, variant: variant),
        ));
        expect(find.text(variant.name), findsOneWidget,
            reason: 'BadgeVariant.${variant.name} should render its label');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // AppColors smoke tests
  // ---------------------------------------------------------------------------

  group('AppColors', () {
    test('primary is the expected lime accent', () {
      expect(AppColors.primary.toARGB32(), equals(0xFFC4EF42));
    });

    test('background and card are distinct colors', () {
      expect(AppColors.background, isNot(equals(AppColors.card)));
    });

    test('foreground is readable over background (not identical)', () {
      expect(AppColors.foreground, isNot(equals(AppColors.background)));
    });
  });
}
