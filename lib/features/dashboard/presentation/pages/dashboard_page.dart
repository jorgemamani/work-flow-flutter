import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/enums/app_user_role.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../widgets/employee_dashboard_body.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final isFieldRole = switch (user.role) {
          AppUserRole.admin => false,
          _ => true,
        };

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: isFieldRole
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EmployeeDashboardHeader(
                      user: user,
                      onLogout: () => _onLogout(context),
                    ),
                    Expanded(
                      child: EmployeeDashboardBody(user: user),
                    ),
                  ],
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Panel admin',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _onLogout(context),
                              icon: const Icon(Icons.logout_rounded),
                              tooltip: 'Cerrar sesión',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        const _AdminDashboardContent(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _onLogout(BuildContext context) {
    AlertManager.showConfirmSheet(
      title: 'Cerrar sesión',
      description: '¿Estás seguro que deseas cerrar sesión?',
      options: [
        SheetOption(
          label: 'Cerrar sesión',
          onTap: () {
            if (context.mounted) {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            }
          },
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

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardCard(
          icon: Icons.inventory_2_rounded,
          title: 'Inventario',
          subtitle: 'Gestionar activos, herramientas y vehículos',
          color: const Color(0xFF10B981),
          onTap: () => context.push(RouteNames.inventory),
        ),
        const SizedBox(height: AppSizes.sm),
        _DashboardCard(
          icon: Icons.manage_accounts_outlined,
          title: 'Usuarios',
          subtitle: 'Gestionar todos los usuarios',
          color: AppColors.error,
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.sm),
        _DashboardCard(
          icon: Icons.settings_outlined,
          title: 'Configuración',
          subtitle: 'Ajustes del sistema',
          color: AppColors.textSecondary,
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.sm),
        _DashboardCard(
          icon: Icons.analytics_outlined,
          title: 'Analytics',
          subtitle: 'Reportes globales',
          color: AppColors.secondary,
          onTap: () {},
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
