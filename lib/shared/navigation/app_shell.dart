import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../routing/route_names.dart';
import '../constants/app_colors.dart';
import '../widgets/app_drawer.dart';

/// Shell persistente que envuelve todas las pantallas autenticadas.
///
/// Responsabilidades:
/// - Renderiza el [BottomNavigationBar] de forma condicional según permisos.
/// - Home y "Más" siempre visibles — "Más" da acceso al drawer (logout).
/// - Inventario: visible si el usuario tiene permisos de herramientas/logística.
/// - Bitácora: para roles de campo, solo si está en obra activa (enObra=true,
///   enDescanso=false, obras no vacías). Para roles globales, basta el permiso.
/// - Los permisos se resuelven antes de montar la barra (sin parpadeos).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthAuthenticated || curr is AuthUnauthenticated,
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = state.user;
        final perms = user.permissions;

        // Calculamos los ítems visibles ANTES de renderizar (evita parpadeos).
        final tabs = _buildTabs(user, perms.showInventoryTab);

        // Si solo hay 1 tab (Home), no mostramos la barra inferior.
        final showBottomNav = tabs.length > 1;

        return Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer(user: user),
          body: widget.navigationShell,
          bottomNavigationBar: showBottomNav
              ? _AppBottomNav(
                  tabs: tabs,
                  currentIndex: _resolveCurrentIndex(tabs),
                  onTap: (index) => _onTabTap(context, tabs, index),
                )
              : null,
        );
      },
    );
  }

  List<_NavTab> _buildTabs(User user, bool showInventory) {
    final perms = user.permissions;

    // Roles de campo (empleado, supervisor, fotógrafo) tienen restricciones
    // adicionales sobre cuándo pueden ver la bitácora.
    final isFieldRole = user.role.isFieldRole;

    final showBitacora = perms.showBitacoraTab(
      isFieldRole: isFieldRole,
      tieneObras: user.obras.isNotEmpty,
    );

    return [
      const _NavTab(
        route: RouteNames.dashboard,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Inicio',
      ),
      if (showInventory)
        const _NavTab(
          route: RouteNames.inventory,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'Inventario',
        ),
      if (showBitacora)
        const _NavTab(
          route: RouteNames.bitacora,
          icon: Icons.book_outlined,
          activeIcon: Icons.book_rounded,
          label: 'Bitácora',
        ),
      // "Más" SIEMPRE visible — es la única forma de acceder al drawer
      // (cuenta + cerrar sesión). Sin este ítem el usuario quedaría atrapado.
      _NavTab(
        route: '',
        icon: Icons.more_horiz_rounded,
        activeIcon: Icons.more_horiz_rounded,
        label: 'Más',
        onTap: (_) => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];
  }

  int _resolveCurrentIndex(List<_NavTab> tabs) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].route.isNotEmpty && location.startsWith(tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _onTabTap(BuildContext context, List<_NavTab> tabs, int index) {
    final tab = tabs[index];
    if (tab.onTap != null) {
      tab.onTap!(context);
      return;
    }
    if (tab.route.isEmpty) return;

    final currentBranch = widget.navigationShell.currentIndex;
    final targetBranch = _branchIndexFor(tab.route);

    if (targetBranch == currentBranch) {
      // Tap en tab activo → volver al root de esa rama.
      widget.navigationShell.goBranch(targetBranch, initialLocation: true);
    } else {
      widget.navigationShell.goBranch(targetBranch);
    }
  }

  int _branchIndexFor(String route) {
    // El orden de ramas en GoRouter: dashboard=0, inventory=1, bitacora=2.
    return switch (route) {
      RouteNames.dashboard => 0,
      RouteNames.inventory => 1,
      RouteNames.bitacora => 2,
      _ => 0,
    };
  }
}

// ── Bottom nav ──────────────────────────────────────────────────────────────

class _NavTab {
  const _NavTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.onTap,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Si no es null, se llama en lugar de navegar a [route].
  final void Function(BuildContext context)? onTap;
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive =
                  tab.route.isNotEmpty && i == currentIndex;
              final color = isActive ? AppColors.primary : AppColors.textSecondary;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
