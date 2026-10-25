import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_extensions.dart';

/// Pestañas: Inicio · Ítems · Escanear · Registros · Cuenta. Escanear va al
/// centro, en tinta, y abre el escáner encima de la pestaña actual. La
/// conexión la muestra [ConnectionFrame] arriba de todo.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int branch) => navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = navigationShell.currentIndex;
    Widget tab(int branch, IconData icon, IconData selectedIcon, String label) => Expanded(
          child: _Tab(
            icon: current == branch ? selectedIcon : icon,
            label: label,
            selected: current == branch,
            onTap: () => _go(branch),
          ),
        );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.bottomNavHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tab(0, Icons.home_outlined, Icons.home, l.tabHome),
                  tab(1, Icons.inventory_2_outlined, Icons.inventory_2, l.tabItems),
                  Expanded(child: _ScanTab(label: l.actionScan)),
                  tab(2, Icons.description_outlined, Icons.description, l.tabRecords),
                  tab(3, Icons.person_outline, Icons.person, l.tabAccount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('navScan'),
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push(RouteNames.scan),
          child: OverflowBox(
            maxHeight: AppSizes.bottomNavHeight + 18,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 26, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontFamily: AppFonts.sans, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      );
}
