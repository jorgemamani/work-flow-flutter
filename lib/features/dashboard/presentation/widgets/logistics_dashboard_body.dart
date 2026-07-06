import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/entities/employee_obra_entities.dart';

/// Dashboard para el rol Logística/Inventario.
/// Vista global de obras y herramientas en modo solo lectura.
/// La carga y modificación de activos se hace desde el tab Inventario.
class LogisticsDashboardBody extends StatelessWidget {
  const LogisticsDashboardBody({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final obras = user.obras;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogisticsHeader(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _ReadOnlyBanner(),
                const SizedBox(height: AppSizes.md),
                _AssetsSummaryRow(obras: obras),
                const SizedBox(height: AppSizes.md),
                const _SectionLabel(label: 'Estado de activos por obra'),
                const SizedBox(height: 8),
                ...obras.map((o) => _ObraAssetCard(obra: o)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogisticsHeader extends StatelessWidget {
  const _LogisticsHeader({required this.user});

  final User user;

  static const _headerGreen = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _headerGreen,
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
            '${user.role.displayLabel} · Solo lectura en esta vista',
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

// ── Widgets internos ─────────────────────────────────────────────────────────

class _ReadOnlyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE047)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFF854D0E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta es una vista de resumen en solo lectura. '
              'Para cargar o modificar activos, usá el tab Inventario.',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF854D0E).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetsSummaryRow extends StatelessWidget {
  const _AssetsSummaryRow({required this.obras});

  final List<ObraAssignment> obras;

  int get _totalItems =>
      obras.fold(0, (acc, o) => acc + o.productos.length);

  int get _enUso => obras.fold(
        0,
        (acc, o) =>
            acc +
            o.productos
                .where((p) => p.status == ObraProductStatus.enUso)
                .length,
      );

  int get _enMantenimiento => obras.fold(
        0,
        (acc, o) =>
            acc +
            o.productos
                .where((p) => p.status == ObraProductStatus.mantenimiento)
                .length,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Total items',
            value: _totalItems.toString(),
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'En uso',
            value: _enUso.toString(),
            icon: Icons.handyman_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'Mantenimiento',
            value: _enMantenimiento.toString(),
            icon: Icons.build_rounded,
            color: AppColors.error,
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _ObraAssetCard extends StatelessWidget {
  const _ObraAssetCard({required this.obra});

  final ObraAssignment obra;

  @override
  Widget build(BuildContext context) {
    final operativos =
        obra.productos.where((p) => p.status == ObraProductStatus.operativo).length;
    final enUso =
        obra.productos.where((p) => p.status == ObraProductStatus.enUso).length;
    final problemas = obra.productos
        .where((p) =>
            p.status == ObraProductStatus.mantenimiento ||
            p.status == ObraProductStatus.averiado)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  obra.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusDot(
                color: AppColors.success,
                label: 'Operativos',
                count: operativos,
              ),
              const SizedBox(width: 12),
              _StatusDot(
                color: AppColors.warning,
                label: 'En uso',
                count: enUso,
              ),
              const SizedBox(width: 12),
              _StatusDot(
                color: AppColors.error,
                label: 'Con problemas',
                count: problemas,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
