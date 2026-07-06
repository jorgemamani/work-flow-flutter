import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/entities/employee_obra_entities.dart';

/// Dashboard para Admin y RRHH: vista global con todas las obras.
/// Admin puede crear/editar; RRHH solo lee en logística pero gestiona empleados.
class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final perms = user.permissions;
    final obras = user.obras;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminHeader(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _SummaryRow(
                  obras: obras,
                  canWriteEmpleados: perms.canWriteEmpleados,
                ),
                const SizedBox(height: AppSizes.md),
                _SectionHeader(
                  title: 'Obras activas',
                  actionLabel: perms.canWriteObras ? 'Nueva obra' : null,
                  onAction: perms.canWriteObras ? () {} : null,
                ),
                const SizedBox(height: 8),
                ...obras.map((o) => _ObraCard(obra: o, perms: perms)),
                const SizedBox(height: AppSizes.md),
                _SectionHeader(
                  title: 'Gestión de personal',
                  actionLabel: perms.canWriteEmpleados ? 'Nuevo empleado' : null,
                  onAction: perms.canWriteEmpleados ? () {} : null,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.people_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Empleados totales',
                  value: _totalCompaneros(obras).toString(),
                  subtitle: 'entre todas las obras',
                ),
                if (perms.canAccessInventory) ...[
                  const SizedBox(height: AppSizes.md),
                  _SectionHeader(
                    title: 'Logística',
                    actionLabel: null,
                    note: perms.canWriteInventory ? null : 'Solo lectura',
                  ),
                  const SizedBox(height: 8),
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Herramientas en uso',
                    value: _totalProductosEnUso(obras).toString(),
                    subtitle: 'Ver detalle en Inventario',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _totalCompaneros(List<ObraAssignment> obras) =>
      obras.fold(0, (acc, o) => acc + o.companeros.length);

  int _totalProductosEnUso(List<ObraAssignment> obras) => obras.fold(
        0,
        (acc, o) =>
            acc +
            o.productos
                .where((p) => p.status == ObraProductStatus.enUso)
                .length,
      );
}

// ── Widgets internos ─────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, ${user.name.split(' ').first}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.role.displayLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.obras, required this.canWriteEmpleados});

  final List<ObraAssignment> obras;
  final bool canWriteEmpleados;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Obras activas',
            value: obras.length.toString(),
            icon: Icons.location_on_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: 'Empleados',
            value: obras
                .fold(0, (acc, o) => acc + o.companeros.length)
                .toString(),
            icon: Icons.people_rounded,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: 'Items activos',
            value: obras
                .fold(0, (acc, o) => acc + o.productos.length)
                .toString(),
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 22,
                ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.note,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (note != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
      ],
    );
  }
}

class _ObraCard extends StatelessWidget {
  const _ObraCard({required this.obra, required this.perms});

  final ObraAssignment obra;
  final dynamic perms;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          title: Text(
            obra.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${obra.companeros.length} empleados · ${obra.productos.length} items',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing:
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: () {},
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
