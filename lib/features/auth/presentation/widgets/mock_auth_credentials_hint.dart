import 'package:flutter/material.dart';

import '../../../../config/mock_auth_config.dart';
import '../../../../config/mock_auth_user.dart';
import '../../../../config/mock_auth_users.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/enums/app_user_role.dart';

/// Panel de acceso rápido a usuarios mock. Solo visible cuando el mock está activo.
class MockAuthCredentialsHint extends StatelessWidget {
  const MockAuthCredentialsHint({super.key, required this.onSelect});

  final void Function(MockAuthUser user) onSelect;

  @override
  Widget build(BuildContext context) {
    if (!MockAuthConfig.isEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                'Usuarios de prueba (mock)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Contraseña para todos: ${MockAuthUsers.defaultPassword}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockAuthUsers.uniqueForDevUi
                .map((u) => _UserChip(user: u, onTap: () => onSelect(u)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user, required this.onTap});

  final MockAuthUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        user.devLabel,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      avatar: Icon(
        _iconForRole(user),
        size: 16,
        color: AppColors.primary,
      ),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  IconData _iconForRole(MockAuthUser user) {
    if (user.obrasScope == MockObrasScope.none) return Icons.person_off_outlined;
    return switch (user.role) {
      AppUserRole.admin => Icons.admin_panel_settings_outlined,
      AppUserRole.rrhh => Icons.groups_outlined,
      AppUserRole.logistica => Icons.inventory_2_outlined,
      AppUserRole.empleadoSupervisor => Icons.supervisor_account_outlined,
      AppUserRole.fotografo => Icons.camera_alt_outlined,
      AppUserRole.empleado => Icons.person_outline,
    };
  }
}
