import 'package:flutter/material.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/utils/color_utils.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_type.dart';
import 'asset_type_theme.dart';

class AssetCard extends StatelessWidget {
  const AssetCard({
    super.key,
    required this.asset,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final Asset asset;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final typeColor = AssetTypeTheme.colorFor(asset.type);
    final condColor =
        colorFromHex(asset.conditionColor) ?? AppColors.textSecondary;
    final condLabel = asset.conditionName ?? '—';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              _TypeIcon(type: asset.type, color: typeColor),
              const SizedBox(width: AppSizes.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _ConditionBadge(
                          label: condLabel,
                          color: condColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),

                    // Brand / model
                    if (asset.brandName != null || asset.modelName != null)
                      _InfoRow(
                        icon: Icons.business_rounded,
                        text: [asset.brandName, asset.modelName]
                            .where((v) => v != null && v.isNotEmpty)
                            .join(' · '),
                      ),

                    // Vehicle: license plate
                    if (asset.type == AssetType.vehicle &&
                        asset.licensePlate != null)
                      _InfoRow(
                        icon: Icons.pin_rounded,
                        text: asset.licensePlate!,
                        bold: true,
                      ),

                    // Serial number
                    if (asset.serialNumber != null &&
                        asset.serialNumber!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.tag_rounded,
                        text: 'S/N: ${asset.serialNumber}',
                      ),

                    // Location
                    if (asset.location != null && asset.location!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_rounded,
                        text: asset.location!,
                      ),

                    // Sub items count (toolBox)
                    if (asset.type == AssetType.toolBox)
                      _InfoRow(
                        icon: Icons.list_alt_rounded,
                        text:
                            '${asset.subItems.length} ítem${asset.subItems.length == 1 ? '' : 's'}',
                      ),

                    const SizedBox(height: AppSizes.xs),

                    // Bottom row: photos + type label + actions
                    Row(
                      children: [
                        // Photo thumbnails
                        if (asset.photoPaths.isNotEmpty)
                          _PhotoThumbnails(paths: asset.photoPaths),
                        const Spacer(),
                        _TypeChip(type: asset.type, color: typeColor),
                        if (onEdit != null || onDelete != null)
                          _ActionsMenu(
                            onEdit: onEdit,
                            onDelete: onDelete,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.color});

  final AssetType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(AssetTypeTheme.iconFor(type), color: color, size: 22),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnails extends StatelessWidget {
  const _PhotoThumbnails({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final show = paths.take(3).toList();
    return Row(
      children: [
        for (final p in show)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AppImage(
                path: p,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (paths.length > 3)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '+${paths.length - 3}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.color});

  final AssetType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
    );
  }
}

