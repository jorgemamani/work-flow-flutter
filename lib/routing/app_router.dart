import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../dependency_injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/bitacora/presentation/pages/bitacora_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/inventory/domain/entities/asset.dart';
import '../features/inventory/presentation/bloc/asset_form_bloc.dart';
import '../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../features/inventory/presentation/pages/asset_detail_page.dart';
import '../features/inventory/presentation/pages/asset_form_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../shared/navigation/app_shell.dart';
import '../shared/pages/account_page.dart';
import 'go_router_refresh_stream.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final _shellNavigatorDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell-dashboard');
final _shellNavigatorInventoryKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell-inventory');
final _shellNavigatorBitacoraKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell-bitacora');

GoRouter buildAppRouter() {
  final authBloc = sl<AuthBloc>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    // Notifica al router cada vez que cambia el estado de auth.
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final loc = state.uri.path;

      final isOnSplash = loc == RouteNames.splash;
      final isOnAuth =
          loc == RouteNames.login || loc == RouteNames.forgotPassword;

      if (authState is AuthLoading || authState is AuthInitial) {
        return isOnSplash ? null : RouteNames.splash;
      }

      if (authState is AuthUnauthenticated) {
        return isOnAuth ? null : RouteNames.login;
      }

      // Autenticado: redirigir splash/login al dashboard.
      if (authState is AuthAuthenticated) {
        if (isOnSplash || isOnAuth) return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      // ── Rutas públicas ─────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ── Rutas sin shell (accesibles desde cualquier parte) ─────────────────
      GoRoute(
        path: RouteNames.account,
        name: 'account',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountPage(),
      ),

      // ── Shell con bottom nav (sección autenticada) ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home / Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),

          // Branch 1: Inventario
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInventoryKey,
            routes: [
              GoRoute(
                path: RouteNames.inventory,
                name: 'inventory',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<InventoryBloc>(),
                  child: const InventoryPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'form',
                    name: 'assetForm',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final asset = state.extra as Asset?;
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => sl<AssetFormBloc>()),
                          BlocProvider(create: (_) => sl<InventoryBloc>()),
                        ],
                        child: AssetFormPage(asset: asset),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'detail',
                    name: 'assetDetail',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final asset = state.extra as Asset;
                      return AssetDetailPage(asset: asset);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Bitácora
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBitacoraKey,
            routes: [
              GoRoute(
                path: RouteNames.bitacora,
                name: 'bitacora',
                builder: (context, state) => const BitacoraPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Instancia singleton del router, construida en [buildAppRouter].
late final GoRouter appRouter;
