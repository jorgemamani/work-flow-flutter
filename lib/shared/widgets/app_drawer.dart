import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../routing/route_names.dart';
import '../constants/app_colors.dart';
import '../managers/alert_manager.dart';


/// Drawer lateral accesible desde el ítem "Más" del bottom nav.
/// Estructura extensible: agregar ítems a [_drawerItems] sin romper el layout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(user: user),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Mi cuenta',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(RouteNames.account);
                    },
                  ),
                  // ── Agregar ítems futuros aquí ──────────────────────────────
                  // _DrawerItem(icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () {}),
                  // _DrawerItem(icon: Icons.help_outline_rounded, label: 'Ayuda', onTap: () {}),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: AppColors.error,
              onTap: () {
                // El AuthBloc se captura ANTES de cerrar el drawer.
                // Si lo leyéramos después del pop(), el context del drawer
                // ya estaría desmontado y context.mounted sería false,
                // impidiendo que el evento se despache.
                final authBloc = context.read<AuthBloc>();
                Navigator.of(context).pop();
                _onLogout(authBloc);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onLogout(AuthBloc authBloc) {
    AlertManager.showConfirmSheet(
      title: 'Cerrar sesión',
      description: '¿Estás seguro que deseas cerrar sesión?',
      options: [
        SheetOption(
          label: 'Cerrar sesión',
          // No necesitamos context.mounted: la referencia al bloc es directa
          // y siempre válida (el AuthBloc es singleton en GetIt).
          onTap: () => authBloc.add(const AuthLogoutRequested()),
        ),
        SheetOption(
          label: 'Cancelar',
          onTap: () {},
          style: SheetOptionStyle.outlined,
        ),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.role.displayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 4,
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      minTileHeight: 52,
    );
  }
}
