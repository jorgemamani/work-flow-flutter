import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/user_type.dart';
import '../../../../shared/managers/alert_manager.dart';

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

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              'Bienvenido, ${user.name.split(' ').first}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _onLogout(context),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserInfoCard(
                    name: user.name,
                    email: user.email,
                    type: user.type,
                    role: user.role,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _buildDashboardContent(context, user.type, user.role),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    UserType type,
    UserRole role,
  ) {
    return switch (type) {
      UserType.employee => _EmployeeDashboard(role: role),
      UserType.manager => _ManagerDashboard(role: role),
      UserType.admin => _AdminDashboard(role: role),
    };
  }

  void _onLogout(BuildContext context) async {
    final confirm = await AlertManager.showConfirm(
      title: 'Cerrar sesión',
      message: '¿Estás seguro que deseas cerrar sesión?',
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
    );
    if (confirm == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    required this.name,
    required this.email,
    required this.type,
    required this.role,
  });

  final String name;
  final String email;
  final UserType type;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    _RoleBadge(type: type),
                    const SizedBox(width: AppSizes.xs),
                    _RoleBadge(role: role),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({this.type, this.role});

  final UserType? type;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (type != null) {
      label = switch (type!) {
        UserType.employee => 'Empleado',
        UserType.manager => 'Manager',
        UserType.admin => 'Admin',
      };
      color = switch (type!) {
        UserType.employee => AppColors.info,
        UserType.manager => AppColors.warning,
        UserType.admin => AppColors.error,
      };
    } else {
      label = 'Rol ${role!.value}';
      color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmployeeDashboard extends StatelessWidget {
  const _EmployeeDashboard({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi panel',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        _DashboardCard(
          icon: Icons.person_outline,
          title: 'Mi información',
          subtitle: 'Ver y gestionar mis datos',
          color: AppColors.primary,
          onTap: () {},
        ),
        if (role.value >= 2) ...[
          const SizedBox(height: AppSizes.sm),
          _DashboardCard(
            icon: Icons.schedule_outlined,
            title: 'Mi horario',
            subtitle: 'Ver mis turnos y horarios',
            color: AppColors.secondary,
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _ManagerDashboard extends StatelessWidget {
  const _ManagerDashboard({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de manager',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        _DashboardCard(
          icon: Icons.group_outlined,
          title: 'Mi equipo',
          subtitle: 'Gestionar empleados',
          color: AppColors.warning,
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.sm),
        _DashboardCard(
          icon: Icons.bar_chart_outlined,
          title: 'Reportes',
          subtitle: 'Ver estadísticas del equipo',
          color: AppColors.success,
          onTap: () {},
        ),
      ],
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de administración',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.md),
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
