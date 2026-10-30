import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/data/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/photos/photo_service.dart';
import '../../../dependency_injection.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_fonts.dart';
import '../../../shared/constants/app_sizes.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/labels.dart';
import '../../../shared/widgets/common.dart';
import '../item_lookup.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({
    super.key,
    required this.asset,
    required this.ctx,
    this.onTap,
    this.trailing,
  });

  final Asset asset;
  final ItemContext ctx;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final model = ctx.models[asset.modelId];
    final where = ctx.where(asset, inTransit: l.inTransit, withPerson: l.withPerson);
    final inTransit = asset.holderType == HolderTypes.inTransit;
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: InkWell(
        key: Key('asset-${asset.internalCode}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowHeight + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                CurrentPhoto(attachmentId: asset.currentPhotoId, size: 52, icon: _icon(model)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model?.name ?? asset.internalCode,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(asset.internalCode, style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary)),
                      if (where.isNotEmpty)
                        Text(
                          where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                trailing ??
                    (inTransit
                        ? StatusChip(l.inTransit, color: AppColors.statusMove)
                        : StatusChip(l.assetStatus(asset.status), color: assetStatusColor(asset.status))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(AssetModel? m) {
    if (m == null) return Icons.inventory_2_outlined;
    if (m.isVehicle) return Icons.local_shipping_outlined;
    if (m.isContainer) return Icons.all_inbox_outlined;
    return Icons.handyman_outlined;
  }
}

/// Foto vigente (RN-22): del caché local; si no está y hay señal, la baja.
class CurrentPhoto extends StatefulWidget {
  const CurrentPhoto({
    super.key,
    required this.attachmentId,
    this.size = 56,
    this.height,
    this.icon = Icons.inventory_2_outlined,
    this.fit = BoxFit.cover,
  });

  final String? attachmentId;
  final double size;

  /// Alto distinto del ancho (foto 4:3 en el detalle).
  final double? height;
  final IconData icon;
  final BoxFit fit;

  @override
  State<CurrentPhoto> createState() => _CurrentPhotoState();
}

class _CurrentPhotoState extends State<CurrentPhoto> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CurrentPhoto old) {
    super.didUpdateWidget(old);
    if (old.attachmentId != widget.attachmentId) _load();
  }

  Future<void> _load() async {
    final id = widget.attachmentId;
    if (id == null) {
      setState(() => _file = null);
      return;
    }
    final photos = sl<PhotoService>();
    final f = await photos.cached(id) ?? await photos.ensure(sl<ApiClient>(), id);
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? widget.size;
    final placeholder = Container(
      width: widget.size,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(widget.icon, color: AppColors.textSecondary),
    );
    final f = _file;
    if (f == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Image.file(
        f,
        width: widget.size,
        height: h,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
