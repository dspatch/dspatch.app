// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'di/providers.dart';
import 'features/auth/backup_codes_screen.dart';
import 'features/auth/device_pairing_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/sas_verification_screen.dart';
import 'features/auth/totp_setup_screen.dart';
import 'features/auth/verify_2fa_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/agent_providers/agent_provider_list_screen.dart';
import 'features/agent_providers/agent_provider_form_screen.dart';
import 'features/engine/engine_screen.dart';
import 'features/inquiries/inquiry_detail_screen.dart';
import 'features/inquiries/inquiry_list_screen.dart';
import 'features/workspaces/workspace_list_screen.dart';
import 'features/workspaces/workspace_create_screen.dart';
import 'features/workspaces/workspace_view_screen.dart';
import 'features/settings/account_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/api_keys_screen.dart';
import 'features/settings/notifications_screen.dart';
import 'features/shell/app_shell.dart';

// ---------------------------------------------------------------------------
// Router provider — reactive to auth state changes
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    initialLocation: '/setup',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider).valueOrNull;
      final path = state.uri.path;
      final isOnAuthRoute = path.startsWith('/auth');

      debugPrint('[ROUTER] redirect: path=$path, auth=${auth?.mode}, scope=${auth?.tokenScope}');

      // Not authenticated — only allow login and registration.
      if (auth == null || auth.mode == AuthMode.undetermined) {
        debugPrint('[ROUTER] Not authenticated, staying on auth');
        if (path == '/auth/login' || path == '/auth/register') return null;
        return '/auth/login';
      }


      final isFullyAuthed = auth.mode == AuthMode.anonymous ||
          (auth.mode == AuthMode.connected &&
              auth.tokenScope == TokenScope.full);

      debugPrint('[ROUTER] isFullyAuthed=$isFullyAuthed');

      // Fully authenticated — send through /setup gateway.
      if (isFullyAuthed) {
        // On auth routes → go to setup (which handles DB init + migration).
        if (isOnAuthRoute) {
          debugPrint('[ROUTER] Fully authed on auth route, -> /setup');
          return '/setup';
        }
        // /setup handles its own redirect to /workspaces when DB is ready.
        // All other app routes are fine — DB must be ready to reach them.
      }

      // Mid-flow redirects for partial auth states. These apply regardless
      // of whether the user is currently on an auth route or an app route.
      if (!isFullyAuthed && auth.mode == AuthMode.connected) {
        if (auth.tokenScope == TokenScope.emailVerification &&
            path != '/auth/verify-email') {
          return '/auth/verify-email';
        }
        if (auth.tokenScope == TokenScope.partial2Fa &&
            path != '/auth/2fa-verify') {
          return '/auth/2fa-verify';
        }
        if (auth.tokenScope == TokenScope.setup2Fa &&
            path != '/auth/2fa-setup') {
          return '/auth/2fa-setup';
        }
        if (auth.tokenScope == TokenScope.awaitingBackupConfirmation &&
            path != '/auth/backup-codes') {
          return '/auth/backup-codes';
        }
        if (auth.tokenScope == TokenScope.deviceRegistration &&
            path != '/auth/device-pairing' &&
            path != '/auth/sas-verify') {
          return '/auth/device-pairing';
        }
      }

      // Not authenticated trying to visit app pages → go to login.
      if (!isFullyAuthed && !isOnAuthRoute) {
        return '/auth/login';
      }

      return null; // No redirect needed.
    },
    routes: [
      // ----- Auth routes (outside AppShell, full-screen) -----
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/auth/verify-email',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: VerifyEmailScreen()),
      ),
      GoRoute(
        path: '/auth/2fa-setup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TotpSetupScreen()),
      ),
      GoRoute(
        path: '/auth/2fa-verify',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: Verify2faScreen()),
      ),
      GoRoute(
        path: '/auth/backup-codes',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: BackupCodesScreen()),
      ),
      GoRoute(
        path: '/auth/device-pairing',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: DevicePairingScreen()),
      ),
      GoRoute(
        path: '/auth/sas-verify',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SasVerificationScreen()),
      ),

      // ----- Catch-all: / redirects to /workspaces -----
      GoRoute(
        path: '/',
        redirect: (_, _) => '/workspaces',
      ),

      // ----- Setup gateway (DB init, migration) -----
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SetupScreen()),
      ),

      // ----- Protected routes (inside AppShell) -----
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/agent-providers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AgentProviderListScreen()),
          ),
          GoRoute(
            path: '/agent-providers/new',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AgentProviderFormScreen()),
          ),
          GoRoute(
            path: '/agent-providers/:id/edit',
            pageBuilder: (context, state) => NoTransitionPage(
              child: AgentProviderFormScreen(
                  id: state.pathParameters['id']),
            ),
          ),
          GoRoute(
            path: '/agent-providers/templates/:id/edit',
            pageBuilder: (context, state) => NoTransitionPage(
              child: AgentProviderFormScreen(
                templateId: state.pathParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: '/agent-providers/templates/new',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AgentProviderFormScreen(isNewTemplate: true)),
          ),
          GoRoute(
            path: '/inquiries',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InquiryListScreen()),
          ),
          GoRoute(
            path: '/workspaces',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorkspaceListScreen()),
          ),
          GoRoute(
            path: '/workspaces/new',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorkspaceCreateScreen()),
          ),
          GoRoute(
            path: '/workspaces/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child:
                  WorkspaceViewScreen(id: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/workspaces/:wid/inquiries/:iid',
            pageBuilder: (context, state) => NoTransitionPage(
              child: InquiryDetailScreen(
                workspaceId: state.pathParameters['wid']!,
                inquiryId: state.pathParameters['iid']!,
              ),
            ),
          ),
          GoRoute(
            path: '/engine',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EngineScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/settings/api-keys',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ApiKeysScreen()),
          ),
          GoRoute(
            path: '/settings/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/settings/account',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountScreen()),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Auth state → GoRouter refresh bridge
// ---------------------------------------------------------------------------

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    _authSub = ref
        .listen<AsyncValue<AuthState>>(authStateProvider, (_, _) {
      notifyListeners();
    });
    _dbSub = ref
        .listen<AsyncValue<DatabaseReadyState>>(databaseStateStreamProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _authSub;
  late final ProviderSubscription<AsyncValue<DatabaseReadyState>> _dbSub;

  @override
  void dispose() {
    _authSub.close();
    _dbSub.close();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// App root widget
// ---------------------------------------------------------------------------

class DspatchApp extends ConsumerStatefulWidget {
  const DspatchApp({super.key});

  @override
  ConsumerState<DspatchApp> createState() => _DspatchAppState();
}

class _DspatchAppState extends ConsumerState<DspatchApp> {
  @override
  void initState() {
    super.initState();
    // Show one-time DB health warning after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(dbHealthStatusProvider);
      if (status == 'repaired') {
        toast('Database was repaired automatically.', type: ToastType.info);
      } else if (status == 'reset') {
        toast(
          'Database was corrupt and has been reset. '
          'Workspace data and settings have been lost.',
          type: ToastType.warning,
          duration: const Duration(seconds: 10),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'd:spatch',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child!,
          const Toaster(),
        ],
      ),
    );
  }
}
