import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../dependency_injection.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/inventory/domain/entities/asset.dart';
import '../features/inventory/presentation/bloc/asset_form_bloc.dart';
import '../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../features/inventory/presentation/pages/asset_detail_page.dart';
import '../features/inventory/presentation/pages/asset_form_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  debugLogDiagnostics: true,
  routes: [
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
    GoRoute(
      path: RouteNames.dashboard,
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: RouteNames.inventory,
      name: 'inventory',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<InventoryBloc>(),
        child: const InventoryPage(),
      ),
    ),
    GoRoute(
      path: RouteNames.assetForm,
      name: 'assetForm',
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
      path: RouteNames.assetDetail,
      name: 'assetDetail',
      builder: (context, state) {
        final asset = state.extra as Asset;
        return AssetDetailPage(asset: asset);
      },
    ),
  ],
);
