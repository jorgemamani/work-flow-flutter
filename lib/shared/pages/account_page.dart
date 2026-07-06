import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../managers/alert_manager.dart';

/// Pantalla de cuenta del usuario.
/// Accesible desde el Drawer → Mi cuenta.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi cuenta'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AvatarSection(user: user),
                const SizedBox(height: AppSizes.md),
                _InfoSection(user: user),
                const SizedBox(height: AppSizes.lg),
                OutlinedButton.icon(
                  onPressed: () => _onLogout(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
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

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.md),
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.displayLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.user});

  final User user;

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
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: user.email),
          const Divider(height: 20),
          _InfoRow(
            label: 'Obras asignadas',
            value: user.obras.isEmpty
                ? 'Ninguna'
                : user.obras.map((o) => o.nombre).join(', '),
          ),
          const Divider(height: 20),
          _InfoRow(label: 'ID de usuario', value: user.id),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
