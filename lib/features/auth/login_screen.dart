// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';
import 'widgets/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(sdkProvider).login(
            username: username,
            password: password,
          );
      // Auth state change triggers route guard -> /auth/2fa-verify
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleAnonymousMode() async {
    setState(() => _isLoading = true);
    await ref.read(sdkProvider).enterAnonymousMode();
    // Auth state change triggers route guard → /sessions
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Login card
          DspatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(text: 'Sign in'),
                      CardDescription(
                        text: 'Enter your credentials to continue.',
                      ),
                    ],
                  ),
                ),
                CardContent(
                  child: Column(
                    children: [
                      Field(
                        label: 'Username',
                        required: true,
                        child: Input(
                          controller: _usernameController,
                          placeholder: 'your_username',
                          prefix: const Icon(LucideIcons.user, size: 18, color: AppColors.mutedForeground),
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Field(
                        label: 'Password',
                        required: true,
                        child: Input(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                          obscureText: _obscurePassword,
                          prefix: const Icon(LucideIcons.lock, size: 18, color: AppColors.mutedForeground),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                              size: 18,
                              color: AppColors.mutedForeground,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                      ),
                    ],
                  ),
                ),
                CardFooter(
                  child: Expanded(
                    child: Button(
                      label: 'Sign in',
                      variant: ButtonVariant.primary,
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error alert
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(
              title: 'Authentication failed',
              message: _error!,
            ),
          ],

          const SizedBox(height: Spacing.xl),
          const Separator(),
          const SizedBox(height: Spacing.xl),

          // Anonymous mode
          Button(
            label: 'Continue without account',
            variant: ButtonVariant.secondary,
            icon: LucideIcons.eye_off,
            onPressed: _isLoading ? null : _handleAnonymousMode,
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Local-only mode \u2014 no sync, no multi-device',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Spacing.xl),

          // TODO: Re-enable when account creation is available
          const Text(
            'Account creation will be available soon.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
