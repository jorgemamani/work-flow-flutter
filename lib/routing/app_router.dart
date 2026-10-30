import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../dependency_injection.dart';
import '../features/account/account_page.dart';
import '../features/account/change_pin_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/select_tenant_page.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/checkins/check_in_page.dart';
import '../features/home/home_page.dart';
import '../features/incidents/incident_form_page.dart';
import '../features/items/item_detail_page.dart';
import '../features/items/items_page.dart';
import '../features/items/move_item_page.dart';
import '../features/items/new_item_page.dart';
import '../features/items/scan_page.dart';
import '../features/items/status_change_page.dart';
import '../features/records/daily_log_form_page.dart';
import '../features/records/records_page.dart';
import '../features/remitos/incoming_remitos_page.dart';
import '../features/remitos/receive_remito_page.dart';
import '../features/remitos/return_remito_page.dart';
import '../features/requirements/requirement_form_page.dart';
import '../features/sync/sync_page.dart';
import '../features/verifications/verification_form_page.dart';
import '../shared/navigation/app_shell.dart';
import 'go_router_refresh_stream.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildAppRouter() {
  final session = sl<SessionCubit>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    // Solo cambios de fase (login, logout, elegir empresa): refrescar con cada
    // cambio de perfil reconstruía las pantallas abiertas y perdía su estado.
    refreshListenable: GoRouterRefreshStream(session.stream.map((s) => s.phase).distinct()),
    redirect: (context, state) {
      final phase = session.state.phase;
      final loc = state.uri.path;
      switch (phase) {
        case SessionPhase.unknown:
          return loc == RouteNames.splash ? null : RouteNames.splash;
        case SessionPhase.unauthenticated:
          return loc == RouteNames.login ? null : RouteNames.login;
        case SessionPhase.choosingTenant:
          return loc == RouteNames.selectTenant ? null : RouteNames.selectTenant;
        case SessionPhase.authenticated:
          if (loc == RouteNames.splash ||
              loc == RouteNames.login ||
              loc == RouteNames.selectTenant) {
            return RouteNames.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: RouteNames.selectTenant,
        builder: (_, __) => const SelectTenantPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.home, builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.items, builder: (_, __) => const ItemsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.records, builder: (_, __) => const RecordsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.account, builder: (_, __) => const AccountPage()),
          ]),
        ],
      ),
      _page(RouteNames.scan, (_) => const ScanPage()),
      _page(
        RouteNames.newItem,
        (s) => NewItemPage(
          initialCode: s.uri.queryParameters['code'],
          initialBarcode: s.uri.queryParameters['barcode'],
        ),
      ),
      _page('${RouteNames.item}/:id', (s) => ItemDetailPage(assetId: s.pathParameters['id']!)),
      _page('${RouteNames.item}/:id/move', (s) => MoveItemPage(assetId: s.pathParameters['id']!)),
      _page('${RouteNames.item}/:id/status', (s) => StatusChangePage(assetId: s.pathParameters['id']!)),
      _page(RouteNames.incomingRemitos, (_) => const IncomingRemitosPage()),
      _page('${RouteNames.remito}/:id/receive', (s) => ReceiveRemitoPage(remitoId: s.pathParameters['id']!)),
      _page(RouteNames.returnRemito, (_) => const ReturnRemitoPage()),
      _page(RouteNames.newVerification, (_) => const VerificationFormPage()),
      _page(RouteNames.newDailyLog, (_) => const DailyLogFormPage()),
      _page(RouteNames.newIncident, (s) => IncidentFormPage(assetId: s.uri.queryParameters['assetId'])),
      _page(RouteNames.newRequirement, (s) => RequirementFormPage(assetId: s.uri.queryParameters['assetId'])),
      _page(RouteNames.checkIn, (_) => const CheckInPage()),
      _page(RouteNames.sync, (_) => const SyncPage()),
      _page(RouteNames.changePin, (_) => const ChangePinPage()),
    ],
  );
}

GoRoute _page(String path, Widget Function(GoRouterState) build) => GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, s) => build(s),
    );

late final GoRouter appRouter;
