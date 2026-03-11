import 'package:flutter/material.dart' hide RadioGroup;

import '../dspatch_ui.dart';

/// A comprehensive demo screen showcasing every dspatch_ui primitive
/// in all its variations.
///
/// Drop this into any app wrapped with the dspatch theme:
/// ```dart
/// MaterialApp(
///   theme: appTheme,           // from dspatch_ui
///   home: Scaffold(
///     backgroundColor: AppColors.background,
///     body: const DemoComponentsScreen(),
///   ),
/// )
/// ```
class DemoComponentsScreen extends StatefulWidget {
  const DemoComponentsScreen({super.key});

  @override
  State<DemoComponentsScreen> createState() => _DemoComponentsScreenState();
}

class _DemoComponentsScreenState extends State<DemoComponentsScreen> {
  // ── State for interactive demos ──────────────────────────────────────
  bool _checkboxChecked = false;
  bool? _checkboxTristate;
  bool _switchValue = false;
  double _sliderValue = 0.4;
  final double _sliderDisabledValue = 0.6;
  String? _radioValue = 'a';
  int _paginationPage = 3;
  String? _selectValue;
  bool _toggleBold = false;
  bool _toggleItalic = false;
  Set<String> _toggleGroupValue = {'bold'};
  Set<String> _textToggleValue = {'center'};
  Set<String> _groupedToggleValue = {'center'};
  Set<String> _compactIconToggleValue = {'bold'};
  Set<String> _variantToggleValue = {'a'};

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading('dspatch_ui Component Gallery'),
                  const SizedBox(height: Spacing.xxl),

                  // ── Buttons ──────────────────────────────────────
                  _section('Button'),
                  _subheading('Variants'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final v in ButtonVariant.values)
                        Button(
                          label: v.name,
                          variant: v,
                          onPressed: () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Sizes'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final s in ButtonSize.values)
                        Button(
                          label: s == ButtonSize.icon ? null : s.name,
                          icon: s == ButtonSize.icon ? LucideIcons.star : null,
                          size: s,
                          onPressed: () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('States'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      Button(label: 'Enabled', onPressed: () {}),
                      const Button(label: 'Disabled'),
                      Button(label: 'Loading', loading: true, onPressed: () {}),
                      Button(
                        icon: LucideIcons.plus,
                        label: 'With Icon',
                        onPressed: () {},
                      ),
                    ],
                  ),

                  _divider(),

                  // ── IconButton ──────────────────────────────────
                  _section('IconButton'),
                  _subheading('Variants'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final v in IconButtonVariant.values)
                        DspatchIconButton(
                          icon: LucideIcons.circle_plus,
                          variant: v,
                          tooltip: v.name,
                          onPressed: () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Sizes'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final s in IconButtonSize.values)
                        DspatchIconButton(
                          icon: LucideIcons.star,
                          size: s,
                          onPressed: () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('States'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DspatchIconButton(
                        icon: LucideIcons.check,
                        tooltip: 'Enabled',
                        onPressed: () {},
                      ),
                      const DspatchIconButton(
                        icon: LucideIcons.ban,
                        tooltip: 'Disabled',
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.refresh_cw,
                        loading: true,
                        tooltip: 'Loading',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.refresh_cw,
                        variant: IconButtonVariant.outline,
                        loading: true,
                        tooltip: 'Loading (outline)',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('With Badge'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DspatchIconButton(
                        icon: LucideIcons.bell,
                        variant: IconButtonVariant.ghost,
                        badge: '',
                        tooltip: 'Notifications (dot)',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.mail,
                        variant: IconButtonVariant.outline,
                        badge: '3',
                        tooltip: 'Mail (count)',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.message_circle,
                        variant: IconButtonVariant.secondary,
                        badge: '12',
                        tooltip: 'Chat (count)',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Common Actions'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DspatchIconButton(
                        icon: LucideIcons.plus,
                        tooltip: 'Add',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.pencil,
                        variant: IconButtonVariant.secondary,
                        tooltip: 'Edit',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.trash_2,
                        variant: IconButtonVariant.destructive,
                        tooltip: 'Delete',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.settings,
                        variant: IconButtonVariant.ghost,
                        tooltip: 'Settings',
                        onPressed: () {},
                      ),
                      DspatchIconButton(
                        icon: LucideIcons.ellipsis_vertical,
                        variant: IconButtonVariant.outline,
                        tooltip: 'More',
                        onPressed: () {},
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Badge ────────────────────────────────────────
                  _section('Badge'),
                  _subheading('All Variants'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final v in BadgeVariant.values)
                        DspatchBadge(label: v.name, variant: v),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('With Icons'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      const DspatchBadge(
                        label: 'Passed',
                        variant: BadgeVariant.success,
                        icon: LucideIcons.circle_check,
                      ),
                      const DspatchBadge(
                        label: 'Failed',
                        variant: BadgeVariant.destructive,
                        icon: LucideIcons.circle_alert,
                      ),
                      const DspatchBadge(
                        label: 'Running',
                        variant: BadgeVariant.info,
                        icon: LucideIcons.play,
                      ),
                      const DspatchBadge(
                        label: 'Warning',
                        variant: BadgeVariant.warning,
                        icon: LucideIcons.triangle_alert,
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Alert ────────────────────────────────────────
                  _section('Alert'),
                  for (final v in AlertVariant.values) ...[
                    Alert(
                      variant: v,
                      children: [
                        AlertTitle(text: '${v.name} alert'),
                        AlertDescription(
                          text: 'This is an example ${v.name} alert with a description.',
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],

                  _divider(),

                  // ── Card ─────────────────────────────────────────
                  _section('Card'),
                  _subheading('Simple Card'),
                  DspatchCard(
                    title: 'Simple Card',
                    description: 'A card with title and description',
                    child: const Text(
                      'This is the card body content.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Composed Card'),
                  DspatchCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CardHeader(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CardTitle(text: 'Account Settings'),
                              CardDescription(
                                text: 'Manage your account preferences below.',
                              ),
                            ],
                          ),
                        ),
                        const CardContent(
                          child: Text(
                            'Configure your notification preferences, privacy settings, and more.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        CardFooter(
                          child: Row(
                            children: [
                              Button(
                                label: 'Cancel',
                                variant: ButtonVariant.outline,
                                onPressed: () {},
                              ),
                              const SizedBox(width: Spacing.sm),
                              Button(label: 'Save', onPressed: () {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Input ────────────────────────────────────────
                  _section('Input'),
                  const SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Input(placeholder: 'Default input'),
                        SizedBox(height: Spacing.sm),
                        Input(placeholder: 'Disabled input', disabled: true),
                        SizedBox(height: Spacing.sm),
                        Input(
                          placeholder: 'Password',
                          obscureText: true,
                        ),
                        SizedBox(height: Spacing.sm),
                        Input(
                          placeholder: 'With prefix',
                          prefix: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        SizedBox(height: Spacing.sm),
                        Input(
                          placeholder: 'Multi-line',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Field ────────────────────────────────────────
                  _section('Field'),
                  SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Field(
                          label: 'Email',
                          required: true,
                          description: 'We will never share your email.',
                          child: Input(placeholder: 'you@example.com'),
                        ),
                        const SizedBox(height: Spacing.lg),
                        const Field(
                          label: 'Username',
                          error: 'This username is already taken.',
                          child: Input(placeholder: 'Enter username'),
                        ),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Label ────────────────────────────────────────
                  _section('Label'),
                  const Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    children: [
                      Label(text: 'Default'),
                      Label(text: 'Required', required: true),
                      Label(text: 'Disabled', disabled: true),
                    ],
                  ),

                  _divider(),

                  // ── Checkbox ─────────────────────────────────────
                  _section('Checkbox'),
                  Wrap(
                    spacing: Spacing.xl,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DspatchCheckbox(
                            value: _checkboxChecked,
                            onChanged: (v) =>
                                setState(() => _checkboxChecked = v ?? false),
                          ),
                          const SizedBox(width: Spacing.sm),
                          const Text(
                            'Standard checkbox',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DspatchCheckbox(
                            value: _checkboxTristate,
                            tristate: true,
                            onChanged: (v) =>
                                setState(() => _checkboxTristate = v),
                          ),
                          const SizedBox(width: Spacing.sm),
                          const Text(
                            'Tristate checkbox',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Switch ───────────────────────────────────────
                  _section('Switch'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DspatchSwitch(
                        value: _switchValue,
                        onChanged: (v) => setState(() => _switchValue = v),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        _switchValue ? 'On' : 'Off',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),

                  _divider(),

                  // ── RadioGroup ───────────────────────────────────
                  _section('RadioGroup'),
                  _subheading('Vertical'),
                  RadioGroup<String>(
                    value: _radioValue,
                    onChanged: (v) => setState(() => _radioValue = v),
                    children: const [
                      RadioGroupItem(value: 'a', label: 'Option A'),
                      RadioGroupItem(
                        value: 'b',
                        label: 'Option B',
                        description: 'With a description',
                      ),
                      RadioGroupItem(
                        value: 'c',
                        label: 'Option C (disabled)',
                        disabled: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Horizontal'),
                  RadioGroup<String>(
                    value: _radioValue,
                    onChanged: (v) => setState(() => _radioValue = v),
                    direction: Axis.horizontal,
                    children: const [
                      RadioGroupItem(value: 'a', label: 'Alpha'),
                      RadioGroupItem(value: 'b', label: 'Beta'),
                      RadioGroupItem(value: 'c', label: 'Gamma'),
                    ],
                  ),

                  _divider(),

                  // ── Slider ───────────────────────────────────────
                  _section('Slider'),
                  _subheading('Interactive'),
                  SizedBox(
                    width: 400,
                    child: DspatchSlider(
                      value: _sliderValue,
                      onChanged: (v) => setState(() => _sliderValue = v),
                    ),
                  ),
                  _subheading('Disabled'),
                  SizedBox(
                    width: 400,
                    child: DspatchSlider(
                      value: _sliderDisabledValue,
                      disabled: true,
                    ),
                  ),
                  _subheading('With Divisions'),
                  SizedBox(
                    width: 400,
                    child: DspatchSlider(
                      value: _sliderValue,
                      divisions: 5,
                      onChanged: (v) => setState(() => _sliderValue = v),
                    ),
                  ),

                  _divider(),

                  // ── Progress ─────────────────────────────────────
                  _section('Progress'),
                  SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Progress(value: 0.0),
                        const SizedBox(height: Spacing.sm),
                        const Progress(value: 0.25),
                        const SizedBox(height: Spacing.sm),
                        const Progress(value: 0.5),
                        const SizedBox(height: Spacing.sm),
                        const Progress(value: 0.75),
                        const SizedBox(height: Spacing.sm),
                        const Progress(value: 1.0),
                        const SizedBox(height: Spacing.lg),
                        _subheading('Custom Height'),
                        const Progress(value: 0.6, height: 4),
                        const SizedBox(height: Spacing.sm),
                        const Progress(value: 0.6, height: 12),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Spinner ──────────────────────────────────────
                  _section('Spinner'),
                  Wrap(
                    spacing: Spacing.xl,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      _LabeledWidget(label: 'sm', child: Spinner(size: SpinnerSize.sm)),
                      _LabeledWidget(label: 'md', child: Spinner(size: SpinnerSize.md)),
                      _LabeledWidget(label: 'lg', child: Spinner(size: SpinnerSize.lg)),
                      _LabeledWidget(
                        label: 'Custom color',
                        child: Spinner(color: AppColors.destructive),
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Skeleton ─────────────────────────────────────
                  _section('Skeleton'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      Skeleton(width: 200, height: 20),
                      Skeleton(width: 150, height: 20),
                      Skeleton(width: 48, height: 48, circle: true),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  _subheading('Card Skeleton'),
                  const Row(
                    children: [
                      Skeleton(width: 48, height: 48, circle: true),
                      SizedBox(width: Spacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(width: 180, height: 14),
                          SizedBox(height: Spacing.xs),
                          Skeleton(width: 120, height: 12),
                        ],
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Avatar ───────────────────────────────────────
                  _section('Avatar'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: const [
                      DspatchAvatar(fallback: 'AB', size: 32),
                      DspatchAvatar(fallback: 'CD', size: 40),
                      DspatchAvatar(fallback: 'EF', size: 48),
                      DspatchAvatar(size: 40),
                    ],
                  ),

                  _divider(),

                  // ── Tooltip ──────────────────────────────────────
                  _section('Tooltip'),
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      DspatchTooltip(
                        message: 'Tooltip below',
                        child: Button(
                          label: 'Hover me (below)',
                          variant: ButtonVariant.outline,
                          onPressed: () {},
                        ),
                      ),
                      DspatchTooltip(
                        message: 'Tooltip above',
                        preferBelow: false,
                        child: Button(
                          label: 'Hover me (above)',
                          variant: ButtonVariant.outline,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Kbd ──────────────────────────────────────────
                  _section('Kbd'),
                  const Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    children: [
                      Kbd(keys: ['⌘', 'K']),
                      Kbd(keys: ['Ctrl', 'Shift', 'P']),
                      Kbd(keys: ['⌘', 'S']),
                      Kbd(keys: ['Esc']),
                    ],
                  ),

                  _divider(),

                  // ── Separator ────────────────────────────────────
                  _section('Separator'),
                  _subheading('Horizontal'),
                  const Separator(),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Vertical (inside Row)'),
                  const SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Left', style: TextStyle(color: AppColors.foreground, fontSize: 13)),
                        SizedBox(width: Spacing.sm),
                        Separator(direction: Axis.vertical, height: 24),
                        SizedBox(width: Spacing.sm),
                        Text('Right', style: TextStyle(color: AppColors.foreground, fontSize: 13)),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Breadcrumb ───────────────────────────────────
                  _section('Breadcrumb'),
                  _subheading('Standard'),
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(label: 'Home', onTap: () {}),
                      BreadcrumbItem(label: 'Products', onTap: () {}),
                      const BreadcrumbItem(label: 'Widget'),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('With Ellipsis (maxItems: 3)'),
                  Breadcrumb(
                    maxItems: 3,
                    items: [
                      BreadcrumbItem(label: 'Home', onTap: () {}),
                      BreadcrumbItem(label: 'Category', onTap: () {}),
                      BreadcrumbItem(label: 'Sub-Category', onTap: () {}),
                      BreadcrumbItem(label: 'Products', onTap: () {}),
                      const BreadcrumbItem(label: 'Widget'),
                    ],
                  ),

                  _divider(),

                  // ── Accordion ────────────────────────────────────
                  _section('Accordion'),
                  _subheading('Single Mode'),
                  const Accordion(
                    type: AccordionType.single,
                    children: [
                      AccordionItem(
                        value: 'item-1',
                        title: 'Is it accessible?',
                        content: Text(
                          'Yes. It adheres to the WAI-ARIA design pattern.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      AccordionItem(
                        value: 'item-2',
                        title: 'Is it styled?',
                        content: Text(
                          'Yes. It ships with default styles matching the dspatch design system.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      AccordionItem(
                        value: 'item-3',
                        title: 'Is it animated?',
                        content: Text(
                          'Yes. It uses smooth expand/collapse animations.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Multiple Mode (with default open)'),
                  const Accordion(
                    type: AccordionType.multiple,
                    defaultValue: {'multi-1'},
                    children: [
                      AccordionItem(
                        value: 'multi-1',
                        title: 'First item (open by default)',
                        content: Text(
                          'This item starts expanded.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      AccordionItem(
                        value: 'multi-2',
                        title: 'Second item',
                        content: Text(
                          'Multiple items can be open at once.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),

                  _divider(),

                  // ── Collapsible ──────────────────────────────────
                  _section('Collapsible'),
                  Collapsible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CollapsibleTrigger(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.chevrons_up_down,
                                size: 16,
                                color: AppColors.mutedForeground,
                              ),
                              SizedBox(width: Spacing.xs),
                              Text(
                                'Toggle Collapsible',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CollapsibleContent(
                          child: Padding(
                            padding: EdgeInsets.only(top: Spacing.sm),
                            child: DspatchCard(
                              child: Text(
                                'This content can be collapsed and expanded.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Tabs ─────────────────────────────────────────
                  _section('Tabs'),
                  DspatchTabs(
                    defaultValue: 'account',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TabsList(
                          children: [
                            TabsTrigger(value: 'account', child: Text('Account')),
                            TabsTrigger(value: 'password', child: Text('Password')),
                            TabsTrigger(value: 'settings', child: Text('Settings')),
                          ],
                        ),
                        const SizedBox(height: Spacing.lg),
                        TabsContent(
                          value: 'account',
                          child: DspatchCard(
                            title: 'Account',
                            description: 'Make changes to your account here.',
                            child: const Input(placeholder: 'Display name'),
                          ),
                        ),
                        TabsContent(
                          value: 'password',
                          child: DspatchCard(
                            title: 'Password',
                            description: 'Change your password here.',
                            child: const Input(
                              placeholder: 'New password',
                              obscureText: true,
                            ),
                          ),
                        ),
                        TabsContent(
                          value: 'settings',
                          child: DspatchCard(
                            title: 'Settings',
                            description: 'Configure your preferences.',
                            child: Row(
                              children: [
                                const Text(
                                  'Enable notifications',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                const SizedBox(width: Spacing.sm),
                                DspatchSwitch(
                                  value: _switchValue,
                                  onChanged: (v) =>
                                      setState(() => _switchValue = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _divider(),

                  // ── Toggle ───────────────────────────────────────
                  _section('Toggle'),
                  _subheading('Default Variant'),
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      Toggle(
                        pressed: _toggleBold,
                        onChanged: (v) => setState(() => _toggleBold = v),
                        child: const Icon(LucideIcons.bold),
                      ),
                      Toggle(
                        pressed: _toggleItalic,
                        onChanged: (v) => setState(() => _toggleItalic = v),
                        child: const Icon(LucideIcons.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Outline Variant'),
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      Toggle(
                        pressed: _toggleBold,
                        variant: ToggleVariant.outline,
                        onChanged: (v) => setState(() => _toggleBold = v),
                        child: const Icon(LucideIcons.bold),
                      ),
                      Toggle(
                        pressed: _toggleItalic,
                        variant: ToggleVariant.outline,
                        onChanged: (v) => setState(() => _toggleItalic = v),
                        child: const Icon(LucideIcons.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Sizes'),
                  Wrap(
                    spacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final s in ToggleSize.values)
                        Toggle(
                          pressed: true,
                          size: s,
                          onChanged: (_) {},
                          child: const Icon(LucideIcons.star),
                        ),
                    ],
                  ),

                  _divider(),

                  // ── ToggleGroup ──────────────────────────────────
                  _section('ToggleGroup'),
                  _subheading('Single Select'),
                  ToggleGroup(
                    type: ToggleGroupType.single,
                    value: _toggleGroupValue,
                    onChanged: (v) => setState(() => _toggleGroupValue = v),
                    children: const [
                      ToggleGroupItem(
                        value: 'bold',
                        child: Icon(LucideIcons.bold),
                      ),
                      ToggleGroupItem(
                        value: 'italic',
                        child: Icon(LucideIcons.italic),
                      ),
                      ToggleGroupItem(
                        value: 'underline',
                        child: Icon(LucideIcons.underline),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Multiple Select (Outline)'),
                  ToggleGroup(
                    type: ToggleGroupType.multiple,
                    variant: ToggleVariant.outline,
                    value: _toggleGroupValue,
                    onChanged: (v) => setState(() => _toggleGroupValue = v),
                    children: const [
                      ToggleGroupItem(
                        value: 'bold',
                        child: Icon(LucideIcons.bold),
                      ),
                      ToggleGroupItem(
                        value: 'italic',
                        child: Icon(LucideIcons.italic),
                      ),
                      ToggleGroupItem(
                        value: 'underline',
                        child: Icon(LucideIcons.underline),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Text Labels'),
                  ToggleGroup(
                    type: ToggleGroupType.single,
                    iconMode: false,
                    value: _textToggleValue,
                    onChanged: (v) =>
                        setState(() => _textToggleValue = v),
                    children: const [
                      ToggleGroupItem(value: 'left', label: 'Left'),
                      ToggleGroupItem(value: 'center', label: 'Center'),
                      ToggleGroupItem(value: 'right', label: 'Right'),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Grouped'),
                  ToggleGroup(
                    style: ToggleGroupStyle.grouped,
                    iconMode: false,
                    value: _groupedToggleValue,
                    onChanged: (v) =>
                        setState(() => _groupedToggleValue = v),
                    children: const [
                      ToggleGroupItem(value: 'left', label: 'Left'),
                      ToggleGroupItem(value: 'center', label: 'Center'),
                      ToggleGroupItem(value: 'right', label: 'Right'),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Grouped with Icons'),
                  ToggleGroup(
                    style: ToggleGroupStyle.grouped,
                    value: _compactIconToggleValue,
                    onChanged: (v) =>
                        setState(() => _compactIconToggleValue = v),
                    children: const [
                      ToggleGroupItem(
                        value: 'bold',
                        child: Icon(LucideIcons.bold),
                      ),
                      ToggleGroupItem(
                        value: 'italic',
                        child: Icon(LucideIcons.italic),
                      ),
                      ToggleGroupItem(
                        value: 'underline',
                        child: Icon(LucideIcons.underline),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Variants (Grouped)'),
                  Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final v in [
                        ToggleVariant.primary,
                        ToggleVariant.secondary,
                        ToggleVariant.destructive,
                        ToggleVariant.accentOutline,
                      ])
                        ToggleGroup(
                          style: ToggleGroupStyle.grouped,
                          variant: v,
                          iconMode: false,
                          value: _variantToggleValue,
                          onChanged: (v) =>
                              setState(() => _variantToggleValue = v),
                          children: const [
                            ToggleGroupItem(value: 'a', label: 'A'),
                            ToggleGroupItem(value: 'b', label: 'B'),
                            ToggleGroupItem(value: 'c', label: 'C'),
                          ],
                        ),
                    ],
                  ),

                  _divider(),

                  // ── Select ───────────────────────────────────────
                  _section('Select'),
                  _subheading('Flat Items'),
                  SizedBox(
                    width: 300,
                    child: Select<String>(
                      value: _selectValue,
                      hint: 'Pick a fruit',
                      items: const [
                        SelectItem(value: 'apple', label: 'Apple'),
                        SelectItem(value: 'banana', label: 'Banana'),
                        SelectItem(value: 'cherry', label: 'Cherry'),
                      ],
                      onChanged: (v) => setState(() => _selectValue = v),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Grouped Items'),
                  SizedBox(
                    width: 300,
                    child: Select<String>(
                      value: _selectValue,
                      hint: 'Pick a food',
                      groups: const [
                        SelectGroup(
                          label: 'FRUITS',
                          items: [
                            SelectItem(value: 'apple', label: 'Apple'),
                            SelectItem(value: 'banana', label: 'Banana'),
                          ],
                        ),
                        SelectGroup(
                          label: 'VEGETABLES',
                          items: [
                            SelectItem(value: 'carrot', label: 'Carrot'),
                            SelectItem(value: 'broccoli', label: 'Broccoli'),
                          ],
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectValue = v),
                    ),
                  ),

                  _divider(),

                  // ── InputOTP ─────────────────────────────────────
                  _section('InputOTP'),
                  _subheading('6-digit'),
                  const InputOTP(length: 6),
                  const SizedBox(height: Spacing.lg),
                  _subheading('4-digit'),
                  const InputOTP(length: 4),

                  _divider(),

                  // ── Pagination ───────────────────────────────────
                  _section('Pagination'),
                  Pagination(
                    currentPage: _paginationPage,
                    totalPages: 10,
                    onPageChanged: (p) => setState(() => _paginationPage = p),
                  ),

                  _divider(),

                  // ── Dialog ───────────────────────────────────────
                  _section('Dialog'),
                  Button(
                    label: 'Open Dialog',
                    variant: ButtonVariant.outline,
                    onPressed: () {
                      DspatchDialog.show(
                        context: context,
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DialogHeader(
                              children: [
                                DialogTitle(text: 'Are you sure?'),
                                DialogDescription(
                                  text: 'This action cannot be undone. This will permanently delete your account.',
                                ),
                              ],
                            ),
                            DialogFooter(
                              children: [
                                Button(
                                  label: 'Cancel',
                                  variant: ButtonVariant.outline,
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                Button(
                                  label: 'Continue',
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  _divider(),

                  // ── Toast (Sonner) ───────────────────────────────
                  _section('Toast (Sonner)'),
                  const Text(
                    'Place a Toaster widget in your widget tree, then call toast().',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      Button(
                        label: 'Normal',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast('Event has been created'),
                      ),
                      Button(
                        label: 'Success',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast(
                          'Success',
                          type: ToastType.success,
                          description: 'Your changes were saved.',
                        ),
                      ),
                      Button(
                        label: 'Error',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast(
                          'Error',
                          type: ToastType.error,
                          description: 'Something went wrong.',
                        ),
                      ),
                      Button(
                        label: 'Warning',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast(
                          'Warning',
                          type: ToastType.warning,
                          description: 'Please review your changes.',
                        ),
                      ),
                      Button(
                        label: 'Info',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast(
                          'Info',
                          type: ToastType.info,
                          description: 'A new version is available.',
                        ),
                      ),
                      Button(
                        label: 'With Action',
                        variant: ButtonVariant.outline,
                        onPressed: () => toast(
                          'File deleted',
                          actionLabel: 'Undo',
                          action: () {},
                        ),
                      ),
                    ],
                  ),

                  _divider(),

                  // ── AlertBanner ──────────────────────────────────
                  _section('AlertBanner'),
                  _subheading('All Variants'),
                  for (final v in AlertBannerVariant.values) ...[
                    AlertBanner(
                      label: '${v.name} banner — Action required.',
                      buttonLabel: 'View',
                      variant: v,
                      onPressed: () {},
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.sm),
                  _subheading('With Meta Text'),
                  AlertBanner(
                    label: 'Deployment in progress',
                    buttonLabel: 'Details',
                    metaText: 'Step 2/5',
                    variant: AlertBannerVariant.info,
                    onPressed: () {},
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Bottom Bar Style'),
                  AlertBanner(
                    label: 'Unsaved changes',
                    buttonLabel: 'Save',
                    isBottomBar: true,
                    variant: AlertBannerVariant.warning,
                    onPressed: () {},
                  ),

                  _divider(),

                  // ── EmptyState ───────────────────────────────────
                  _section('EmptyState'),
                  _subheading('Standard'),
                  DspatchCard(
                    child: EmptyState(
                      icon: LucideIcons.inbox,
                      title: 'No messages',
                      description: 'You have no messages yet. Start a conversation.',
                      actions: [
                        Button(
                          label: 'Compose',
                          icon: LucideIcons.plus,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Compact'),
                  DspatchCard(
                    child: EmptyState(
                      icon: LucideIcons.search_x,
                      title: 'No results',
                      description: 'Try adjusting your search criteria.',
                      compact: true,
                    ),
                  ),

                  _divider(),

                  // ── StatusCard ───────────────────────────────────
                  _section('StatusCard'),
                  const StatusCard(
                    icon: LucideIcons.circle_check,
                    color: AppColors.success,
                    text: 'All systems operational',
                  ),
                  const SizedBox(height: Spacing.sm),
                  StatusCard(
                    icon: LucideIcons.circle_alert,
                    color: AppColors.error,
                    text: 'Connection failed',
                    trailing: Button(
                      label: 'Retry',
                      size: ButtonSize.sm,
                      variant: ButtonVariant.ghost,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  const StatusCard(
                    icon: LucideIcons.refresh_cw,
                    color: AppColors.info,
                    text: 'Syncing data...',
                    showSpinner: true,
                  ),

                  _divider(),

                  // ── Stepper ──────────────────────────────────────
                  _section('Stepper'),
                  _subheading('Step 2 of 5 (Active)'),
                  const DspatchStepper(totalSteps: 5, currentStep: 2),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Step 3 of 4 (Waiting)'),
                  const DspatchStepper(
                    totalSteps: 4,
                    currentStep: 3,
                    isWaiting: true,
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('All Complete'),
                  const DspatchStepper(
                    totalSteps: 3,
                    currentStep: 4,
                    completedSteps: 3,
                  ),

                  _divider(),

                  // ── PulsingDot ───────────────────────────────────
                  _section('PulsingDot'),
                  Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      PulsingDot(color: AppColors.success),
                      PulsingDot(color: AppColors.info, label: '2'),
                      PulsingDot(color: AppColors.warning, size: 32),
                      PulsingDot(color: AppColors.error, size: 16),
                    ],
                  ),

                  _divider(),

                  // ── AutoRefreshButton ──────────────────────────
                  _section('AutoRefreshButton'),
                  _subheading('Default (Primary)'),
                  AutoRefreshButton(
                    interval: const Duration(seconds: 15),
                    onRefresh: () =>
                        toast('Refreshed', type: ToastType.success),
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Variants'),
                  Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final v in [
                        ButtonVariant.primary,
                        ButtonVariant.secondary,
                        ButtonVariant.outline,
                        ButtonVariant.destructive,
                      ])
                        AutoRefreshButton(
                          interval: const Duration(seconds: 10),
                          variant: v,
                          onRefresh: () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _subheading('Sizes'),
                  Wrap(
                    spacing: Spacing.lg,
                    runSpacing: Spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final s in [24.0, 28.0, 36.0])
                        AutoRefreshButton(
                          interval: const Duration(seconds: 10),
                          size: s,
                          onRefresh: () {},
                        ),
                    ],
                  ),

                  _divider(),

                  // ── TerminalLogView ──────────────────────────────
                  _section('TerminalLogView'),
                  TerminalLogView(
                    logs: [
                      const LogEntry("POST /api/auth/register  user=test@example.com"),
                      const LogEntry("  → 201  token=yes"),
                      const LogEntry("GET /api/agents"),
                      const LogEntry("  → 200  count=3"),
                      const LogEntry("Fixture: seed test data"),
                      const LogEntry("DB: INSERT INTO users (email) VALUES ('admin@dspatch.dev')"),
                      const LogEntry("DELETE /api/agents/abc-123"),
                      const LogEntry("  → 404  error='Not found'", level: 'warn'),
                      const LogEntry("GET /api/health"),
                      const LogEntry("  → 500  error='Internal server error'", level: 'error'),
                    ],
                    error: 'Connection timeout after 30s',
                    maxHeight: 250,
                    expand: false,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    copyText: 'POST /api/auth/register...',
                  ),

                  _divider(),

                  // ── Color Palette ────────────────────────────────
                  _section('Color Palette'),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: const [
                      _ColorSwatch('background', AppColors.background),
                      _ColorSwatch('foreground', AppColors.foreground),
                      _ColorSwatch('card', AppColors.card),
                      _ColorSwatch('primary', AppColors.primary),
                      _ColorSwatch('secondary', AppColors.secondary),
                      _ColorSwatch('muted', AppColors.muted),
                      _ColorSwatch('accent', AppColors.accent),
                      _ColorSwatch('destructive', AppColors.destructive),
                      _ColorSwatch('border', AppColors.border),
                      _ColorSwatch('success', AppColors.success),
                      _ColorSwatch('info', AppColors.info),
                      _ColorSwatch('warning', AppColors.warning),
                      _ColorSwatch('error', AppColors.error),
                      _ColorSwatch('accentSoft', AppColors.accentSoft),
                      _ColorSwatch('accentMuted', AppColors.accentMuted),
                      _ColorSwatch('surfaceHover', AppColors.surfaceHover),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        const Toaster(position: ToasterPosition.bottomRight),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _heading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        fontFamily: AppFonts.sans,
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          fontFamily: AppFonts.sans,
        ),
      ),
    );
  }

  Widget _subheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
          fontFamily: AppFonts.sans,
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Separator(),
    );
  }
}

// ── Private helper widgets ───────────────────────────────────────────────

class _LabeledWidget extends StatelessWidget {
  const _LabeledWidget({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: Spacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
            fontFamily: AppFonts.mono,
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.mutedForeground,
            fontFamily: AppFonts.mono,
          ),
        ),
      ],
    );
  }
}
