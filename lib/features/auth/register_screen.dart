// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import 'widgets/auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Client-side validation
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 12) {
      setState(() => _error = 'Password must be at least 12 characters.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success =
          await ref.read(authControllerProvider.notifier).register(
                username: username,
                email: email,
                password: password,
              );
      if (!mounted) return;
      if (!success) {
        setState(() => _isLoading = false);
      }
      // Router redirects based on authPhaseProvider.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      stepperStep: 1,
      stepperTotal: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DspatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(text: 'Create account'),
                      CardDescription(
                        text: 'Register to sync sessions across devices.',
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
                          prefix: const Icon(LucideIcons.user,
                              size: 18, color: AppColors.mutedForeground),
                          onSubmitted: (_) => _emailFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Field(
                        label: 'Email',
                        required: true,
                        child: Input(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          placeholder: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefix: const Icon(LucideIcons.mail,
                              size: 18, color: AppColors.mutedForeground),
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Field(
                        label: 'Password',
                        required: true,
                        description: 'Minimum 12 characters',
                        child: Input(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                          obscureText: _obscurePassword,
                          prefix: const Icon(LucideIcons.lock,
                              size: 18, color: AppColors.mutedForeground),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                              size: 18,
                              color: AppColors.mutedForeground,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Field(
                        label: 'Confirm password',
                        required: true,
                        child: Input(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          placeholder: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                          obscureText: _obscureConfirmPassword,
                          prefix: const Icon(LucideIcons.lock,
                              size: 18, color: AppColors.mutedForeground),
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? LucideIcons.eye_off : LucideIcons.eye,
                              size: 18,
                              color: AppColors.mutedForeground,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          onSubmitted: (_) => _handleRegister(),
                        ),
                      ),
                    ],
                  ),
                ),
                CardFooter(
                  child: Expanded(
                    child: Button(
                      label: 'Create account',
                      variant: ButtonVariant.primary,
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _handleRegister,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            ErrorAlert(
              title: 'Registration failed',
              message: _error!,
            ),
          ],

          const SizedBox(height: Spacing.xl),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(width: 4),
              Button(
                label: 'Sign in',
                variant: ButtonVariant.link,
                onPressed: () => context.go('/auth/login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
