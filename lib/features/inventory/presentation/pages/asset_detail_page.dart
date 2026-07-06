import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';
import '../widgets/asset_type_theme.dart';

class AssetDetailPage extends StatelessWidget {
  const AssetDetailPage({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final typeColor = AssetTypeTheme.colorFor(asset.type);
    final condColor = AssetTypeTheme.conditionColor(asset.condition);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar con foto o color de tipo
          SliverAppBar(
            expandedHeight: asset.photoPaths.isNotEmpty ? 220 : 120,
            pinned: true,
            backgroundColor: typeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => context.push(
                  RouteNames.assetForm,
                  extra: asset,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: asset.photoPaths.isNotEmpty
                  ? _HeroPhoto(path: asset.photoPaths.first)
                  : Container(
                      color: typeColor,
                      child: Center(
                        child: Icon(
                          AssetTypeTheme.iconFor(asset.type),
                          size: 60,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          asset.description,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _TypeBadge(type: asset.type, color: typeColor),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),

                  // Condition badge
                  _ConditionBadge(
                    condition: asset.condition,
                    color: condColor,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Identificación ─────────────────────────────────
                  _DetailSection(title: 'Identificación', children: [
                    if (asset.type == AssetType.vehicle &&
                        asset.licensePlate != null)
                      _DetailRow(
                        icon: Icons.pin_rounded,
                        label: 'Patente',
                        value: asset.licensePlate!,
                        highlight: true,
                      ),
                    if (asset.brandName != null)
                      _DetailRow(
                        icon: Icons.business_rounded,
                        label: 'Marca',
                        value: asset.brandName!,
                      ),
                    if (asset.modelName != null)
                      _DetailRow(
                        icon: Icons.category_rounded,
                        label: 'Modelo',
                        value: asset.modelName!,
                      ),
                    if (asset.serialNumber != null)
                      _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'N° de serie',
                        value: asset.serialNumber!,
                      ),
                    if (asset.color != null)
                      _DetailRow(
                        icon: Icons.palette_rounded,
                        label: 'Color',
                        value: asset.color!,
                      ),
                    if (asset.quantity > 1)
                      _DetailRow(
                        icon: Icons.numbers_rounded,
                        label: 'Cantidad',
                        value: asset.quantity.toString(),
                      ),
                    if (asset.location != null)
                      _DetailRow(
                        icon: Icons.place_rounded,
                        label: 'Ubicación',
                        value: asset.location!,
                      ),
                  ]),

                  // ── Vehículo ───────────────────────────────────────
                  if (asset.type == AssetType.vehicle) ...[
                    const SizedBox(height: AppSizes.md),
                    _DetailSection(
                        title: 'Datos del vehículo',
                        children: [
                          if (asset.year != null)
                            _DetailRow(
                              icon: Icons.date_range_rounded,
                              label: 'Año',
                              value: asset.year.toString(),
                            ),
                          if (asset.engineNumber != null)
                            _DetailRow(
                              icon: Icons.settings_rounded,
                              label: 'N° motor',
                              value: asset.engineNumber!,
                            ),
                          if (asset.chassisNumber != null)
                            _DetailRow(
                              icon: Icons.confirmation_number_rounded,
                              label: 'Chasis / VIN',
                              value: asset.chassisNumber!,
                            ),
                          if (asset.mileage != null)
                            _DetailRow(
                              icon: Icons.speed_rounded,
                              label: 'Kilómetros',
                              value:
                                  '${NumberFormat('#,###').format(asset.mileage)} km',
                            ),
                          if (asset.vtvExpiry != null)
                            _DetailRow(
                              icon: Icons.verified_rounded,
                              label: 'Vence VTV',
                              value: DateFormat('dd/MM/yyyy')
                                  .format(asset.vtvExpiry!),
                              highlight: _isExpiringSoon(asset.vtvExpiry!),
                            ),
                          if (asset.insuranceExpiry != null)
                            _DetailRow(
                              icon: Icons.shield_rounded,
                              label: 'Vence seguro',
                              value: DateFormat('dd/MM/yyyy')
                                  .format(asset.insuranceExpiry!),
                              highlight:
                                  _isExpiringSoon(asset.insuranceExpiry!),
                            ),
                        ]),
                  ],

                  // ── Sub-ítems ──────────────────────────────────────
                  if (asset.type == AssetType.toolBox &&
                      asset.subItems.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.md),
                    _DetailSection(
                      title:
                          'Contenido (${asset.subItems.length} ítems)',
                      children: [
                        for (var i = 0; i < asset.subItems.length; i++)
                          _SubItemRow(
                            index: i + 1,
                            item: asset.subItems[i],
                          ),
                      ],
                    ),
                  ],

                  // ── Observaciones ──────────────────────────────────
                  if (asset.observations != null &&
                      asset.observations!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.md),
                    _DetailSection(title: 'Observaciones', children: [
                      Text(
                        asset.observations!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ]),
                  ],

                  // ── Fotos ──────────────────────────────────────────
                  if (asset.photoPaths.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.md),
                    _DetailSection(
                      title:
                          'Fotos (${asset.photoPaths.length})',
                      children: [_PhotoGrid(paths: asset.photoPaths)],
                    ),
                  ],

                  // ── Fechas ─────────────────────────────────────────
                  const SizedBox(height: AppSizes.md),
                  _DetailSection(title: 'Registro', children: [
                    _DetailRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Cargado',
                      value: DateFormat('dd/MM/yyyy HH:mm')
                          .format(asset.createdAt),
                    ),
                    _DetailRow(
                      icon: Icons.update_rounded,
                      label: 'Actualizado',
                      value: DateFormat('dd/MM/yyyy HH:mm')
                          .format(asset.updatedAt),
                    ),
                  ]),

                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isExpiringSoon(DateTime date) {
    return date.isBefore(DateTime.now().add(const Duration(days: 30)));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.color});

  final AssetType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AssetTypeTheme.iconFor(type), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.condition, required this.color});

  final AssetCondition condition;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        condition.displayName,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: children[i],
                ),
                if (i < children.length - 1)
                  const Divider(
                    height: 1,
                    color: AppColors.divider,
                    indent: AppSizes.md,
                    endIndent: AppSizes.md,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.index, required this.item});

  final int index;
  final AssetSubItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (item.brandName != null || item.serialNumber != null)
                Text(
                  [
                    if (item.brandName != null) item.brandName,
                    if (item.serialNumber != null)
                      'S/N: ${item.serialNumber}',
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        if (item.quantity > 1)
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
      ),
      itemCount: paths.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.file(
          File(paths[i]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.border,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}
