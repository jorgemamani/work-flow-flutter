import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/entities/employee_obra_entities.dart';
import '../../../../shared/widgets/employee_status_badge.dart';

/// Vista de campo: empleado / supervisor / fotógrafo.
/// Solo lectura. El acceso a inventario está en el bottom nav.
class EmployeeDashboardBody extends StatefulWidget {
  const EmployeeDashboardBody({super.key, required this.user});

  final User user;

  @override
  State<EmployeeDashboardBody> createState() => _EmployeeDashboardBodyState();
}

class _EmployeeDashboardBodyState extends State<EmployeeDashboardBody> {
  int _obraIndex = 0;

  @override
  void didUpdateWidget(covariant EmployeeDashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_obraIndex >= widget.user.obras.length) {
      _obraIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final obras = user.obras;
    final perms = user.permissions;
    final status = EmployeeStatus.fromBools(
      enObra: perms.enObra,
      enDescanso: perms.enDescanso,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmployeeHeader(user: user, status: status),
          Expanded(
            child: obras.isEmpty
                ? _EmptyObrasView(status: status)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (obras.length > 1) ...[
                          _ObraPicker(
                            obras: obras,
                            selectedIndex: _obraIndex,
                            onChanged: (i) => setState(() => _obraIndex = i),
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                        _ObraActualCard(obra: obras[_obraIndex]),
                        const SizedBox(height: AppSizes.md),
                        _CompanerosCard(obra: obras[_obraIndex]),
                        const SizedBox(height: AppSizes.md),
                        _ProductosCard(obra: obras[_obraIndex]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.user, required this.status});

  final User user;
  final EmployeeStatus status;

  static const _headerBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _headerBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de estado — reutilizable en todas las pantallas.
              EmployeeStatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyObrasView extends StatelessWidget {
  const _EmptyObrasView({required this.status});

  final EmployeeStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No estás asignado a ninguna obra',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando te asignen a una obra, vas a ver los detalles, '
              'compañeros y herramientas disponibles acá.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.contact_support_outlined, size: 18),
              label: const Text('Contactar a mi supervisor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Obra picker ──────────────────────────────────────────────────────────────

class _ObraPicker extends StatelessWidget {
  const _ObraPicker({
    required this.obras,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ObraAssignment> obras;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis obras',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seleccioná en cuál estás trabajando ahora',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(obras.length, (i) {
              final selected = i == selectedIndex;
              return FilterChip(
                label: Text(obras[i].nombre),
                selected: selected,
                onSelected: (_) => onChanged(i),
                showCheckmark: true,
                selectedColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF2196F3),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _ObraActualCard extends StatelessWidget {
  const _ObraActualCard({required this.obra});

  final ObraAssignment obra;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      iconBg: const Color(0xFFE3F2FD),
      iconFg: const Color(0xFF1976D2),
      icon: Icons.location_on_rounded,
      title: 'Obra Actual',
      subtitle: 'Tu asignación activa',
      child: Column(
        children: [
          _InfoRow(label: 'Nombre', value: obra.nombre),
          _InfoRow(label: 'Ubicación', value: obra.ubicacion),
          _InfoRow(label: 'Supervisor', value: obra.supervisorNombre),
        ],
      ),
    );
  }
}

class _CompanerosCard extends StatelessWidget {
  const _CompanerosCard({required this.obra});

  final ObraAssignment obra;

  @override
  Widget build(BuildContext context) {
    final n = obra.companeros.length;
    return _SectionCard(
      iconBg: const Color(0xFFE8F5E9),
      iconFg: const Color(0xFF2E7D32),
      icon: Icons.groups_rounded,
      title: 'Compañeros de Obra',
      subtitle: '$n ${n == 1 ? 'miembro' : 'miembros'}',
      child: Column(
        children: obra.companeros
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.nombre,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.puesto,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProductosCard extends StatelessWidget {
  const _ProductosCard({required this.obra});

  final ObraAssignment obra;

  @override
  Widget build(BuildContext context) {
    final n = obra.productos.length;
    return _SectionCard(
      iconBg: const Color(0xFFF3E5F5),
      iconFg: const Color(0xFF7B1FA2),
      icon: Icons.inventory_2_rounded,
      title: 'Herramientas y Productos',
      subtitle: '$n ${n == 1 ? 'item' : 'items'}',
      child: Column(
        children: obra.productos
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: ${p.cantidad}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: p.status),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Reusables ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconFg, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
            ],
          ),
          const SizedBox(height: 16),
          child,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ObraProductStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ObraProductStatus.operativo => (
          AppColors.success.withValues(alpha: 0.15),
          AppColors.success
        ),
      ObraProductStatus.enUso => (
          AppColors.warning.withValues(alpha: 0.2),
          const Color(0xFFB45309)
        ),
      ObraProductStatus.mantenimiento => (
          AppColors.info.withValues(alpha: 0.15),
          AppColors.info
        ),
      ObraProductStatus.averiado => (
          AppColors.error.withValues(alpha: 0.15),
          AppColors.error
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
