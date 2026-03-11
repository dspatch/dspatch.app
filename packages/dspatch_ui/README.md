# dspatch_ui

**Shared design system for d:spatch Flutter applications.**

This package is the single source of truth for all design tokens, theme configuration, and shared UI primitives used by both the user app (`app/`) and the operator admin app (`admin_app/`).

---

## Usage

**User app** (self-contained — package is inside the repo):

```yaml
# app/pubspec.yaml
dependencies:
  dspatch_ui:
    path: packages/dspatch_ui
```

**Admin app** (sibling in monorepo):

```yaml
# admin_app/pubspec.yaml
dependencies:
  dspatch_ui:
    path: ../app/packages/dspatch_ui
```

---

## Package Structure

```
dspatch_ui/
├── lib/
│   ├── dspatch_ui.dart                # barrel export
│   ├── src/
│   │   ├── theme/
│   │   │   ├── app_theme.dart         # ThemeData builder (light + dark)
│   │   │   ├── colors.dart            # color palette tokens
│   │   │   ├── typography.dart        # text styles, font families
│   │   │   └── spacing.dart           # spacing scale, border radii
│   │   └── widgets/
│   │       ├── ds_button.dart         # primary, secondary, ghost, destructive
│   │       ├── ds_card.dart           # bordered card with hover state
│   │       ├── ds_input.dart          # text field with label, error, password toggle
│   │       ├── ds_dialog.dart         # modal dialog with action buttons
│   │       ├── ds_badge.dart          # status badge (success, warning, error, info)
│   │       ├── ds_tabs.dart           # tab bar with underline indicator
│   │       ├── ds_table.dart          # sortable, paginated data table
│   │       ├── ds_empty_state.dart    # illustration + message + action
│   │       ├── ds_loading.dart        # skeleton loader
│   │       ├── ds_error.dart          # error message with retry
│   │       ├── search_bar.dart        # search input with clear button
│   │       └── filter_chips.dart      # filter chip group
├── assets/
│   └── fonts/
│       ├── DMMono-Light.ttf
│       ├── DMMono-LightItalic.ttf
│       ├── DMMono-Regular.ttf
│       ├── DMMono-Italic.ttf
│       ├── DMMono-Medium.ttf
│       ├── DMMono-MediumItalic.ttf
│       ├── DMSerifDisplay-Regular.ttf
│       └── DMSerifDisplay-Italic.ttf
├── pubspec.yaml
└── README.md                          # this file
```

---

## Design Philosophy

**Component-based and dark-first.** The design system shares the same visual language as the d:spatch marketing website: DM Mono for UI/code, DM Serif Display for headings, a dark purple background, and a lime accent. This ensures design continuity — a visitor's first impression on the website matches the app experience.

All widgets are prefixed with `Ds` (Design System) to distinguish from Flutter built-ins.

---

## Color Palette

The palette mirrors the marketing website's design tokens (WEBSITE.md), providing brand continuity across all surfaces.

### Core Tokens

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | `#FFFFFF` | `#1a1a2a` | Page background |
| `backgroundDeep` | `#F8F8FA` | `#141420` | Code blocks, terminal, deeper sections |
| `foreground` | `#1a1a2a` | `#e8e6e3` | Primary text |
| `card` | `#FFFFFF` | `#252536` | Card surfaces |
| `cardHover` | `#F8F8FA` | `#2a2a3c` | Hover states |
| `muted` | `#F4F4F5` | `#33334a` | Subtle backgrounds, disabled states |
| `mutedForeground` | `#6c6b7b` | `#b0aec0` | Secondary text, placeholders |
| `dimForeground` | `#9c9bab` | `#6c6b7b` | Captions, metadata |

### Primary & Accent

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#1a1a2a` | `#e8e6e3` | Primary buttons, active states |
| `primaryForeground` | `#FFFFFF` | `#1a1a2a` | Text on primary |
| `accent` | `#8cc828` | `#c4f042` | Primary accent (lime green) — CTAs, active indicators, links |
| `accentSoft` | `#a8e040` | `#d4f572` | Lighter accent for hover |
| `accentDim` | `rgba(140,200,40,0.07)` | `rgba(196,240,66,0.07)` | Accent backgrounds |

### Semantic & Utility

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `destructive` | `#EF4444` | `#EF4444` | Delete, error states |
| `border` | `#E4E4E7` | `#33334a` | Borders, dividers |
| `borderSubtle` | `#F0F0F2` | `#2a2a3e` | Grid lines, very subtle borders |
| `ring` | `#8cc828` | `#c4f042` | Focus rings (accent-colored) |

### Semantic Status Colors (dark mode)

Used by `DsBadge`, health indicators, and terminal output:

| Token | Value | Usage |
|-------|-------|-------|
| `success` | `#9DCE68` | Healthy, passed, connected |
| `info` | `#78A0F7` | Informational states |
| `warning` | `#DFAF66` | Degraded, stale, caution |
| `error` | `#F7788F` | Failed, unreachable, critical |

---

## Typography

Two font families matching the marketing website, bundled in `assets/fonts/`:

- **DM Mono** — body text, UI elements, code blocks, navigation (weights 300, 400, 500)
- **DM Serif Display** — page titles, hero headlines, section headings (Regular, Italic)

### Text Styles

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| `displayLg` | DM Serif Display | 32 | Regular | Hero/splash headings |
| `headingLg` | DM Serif Display | 24 | Regular | Page titles |
| `headingSm` | DM Mono | 18 | Medium (500) | Section headers |
| `body` | DM Mono | 14 | Regular (400) | Body text |
| `bodySm` | DM Mono | 12 | Regular (400) | Secondary text, timestamps |
| `code` | DM Mono | 13 | Light (300) | Code blocks, log output |
| `label` | DM Mono | 12 | Medium (500) | Form labels, badges |

---

## Spacing Scale

Consistent 4px grid system:

```
xs   =  4px
sm   =  8px
md   = 12px
lg   = 16px
xl   = 20px
xxl  = 24px
3xl  = 32px
4xl  = 40px
5xl  = 48px
6xl  = 64px
```

### Border Radii

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 6px | Small buttons, badges |
| `md` | 8px | Inputs, dialogs |
| `lg` | 10px | Cards |

---

## Widget Catalog

All widgets accept theming from the `AppTheme` and use the color/spacing tokens above.

| Widget | Description |
|--------|-------------|
| `DsButton` | Primary, secondary, ghost, destructive variants. Loading state. Icon support. |
| `DsCard` | Bordered card with consistent padding and hover state. |
| `DsInput` | Text field with label, hint, error, prefix/suffix. Password mask toggle. |
| `DsDialog` | Modal dialog with title, content, action buttons. |
| `DsBadge` | Status badge (colored dot + label). Variants: default, success, warning, error, info. |
| `DsTabs` | Tab bar with underline indicator and lazy content loading. |
| `DsTable` | Sortable, paginated data table with row actions. |
| `DsEmptyState` | Illustration + message + action button for empty lists. |
| `DsLoading` | Skeleton loader matching the content shape. |
| `DsError` | Error message with retry button. |
| `SearchBar` | Search input with debounce and clear button. |
| `FilterChips` | Horizontal chip group for filtering lists. |

### App-Specific Widgets (not in this package)

Some widgets are specific to one app and live in that app's codebase:

**User app** (`app/lib/shared/widgets/`):
- `LiveIndicator` — pulsing green dot for streaming/live data
- `MarkdownView` — markdown renderer (depends on `flutter_markdown`)
- `CodeView` — syntax-highlighted code display (depends on `flutter_code_editor`)

**Admin app** (`admin_app/lib/shared/widgets/`):
- `ConfirmationDialog` — "type name to confirm" pattern for destructive actions
- `AutoRefreshIndicator` — countdown ring showing time until next poll

---

## Theme Structure

```dart
class AppTheme {
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: _textTheme,
    cardTheme: _cardTheme,
    inputDecorationTheme: _inputTheme,
    // ... component themes
  );

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: _textTheme,
    // ...
  );
}
```

Both apps use `AppTheme.dark()` as the default. The user app also supports `AppTheme.light()` for user preference; the admin app is dark-only.
