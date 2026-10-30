import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/profile.dart';
import '../../core/data/models.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/theme/tenant_brand.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/live_query.dart';
import '../../shared/widgets/connection_strip.dart';
import '../auth/presentation/session_cubit.dart';
import 'item_lookup.dart';
import 'widgets/asset_tile.dart';

/// Detalle del ítem con su foto vigente, dónde está y qué contiene. Desde
/// acá se mueve, se cambia el estado o se reporta algo.
class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final profile = session.profile!;
    return LiveQuery<ItemContext>(
      sources: itemSources,
      query: ItemContext.load,
      builder: (context, ctx) {
        final a = ctx.assets[assetId];
        if (a == null) {
          return FieldScaffold(
            body: EmptyState(icon: Icons.search_off, text: l.itemNotFound),
          );
        }
        final model = ctx.models[a.modelId];
        final brand = ctx.brands[model?.brandId];
        final can = ItemAbilities.of(a, profile: profile, projectId: session.projectId);
        final contents = ctx.contents(a);
        final custodian = ctx.employees[a.custodianEmployeeId]?.fullName;
        final chain = ctx.resolver.chain(a);
        final inTransit = a.holderType == HolderTypes.inTransit;
        final actions = <Widget>[
          if (can.canMove)
            _ActionRow(
              key: const Key('moveItem'),
              icon: Icons.arrow_forward,
              label: l.moveItem,
              onTap: () => context.push(RouteNames.moveItem(a.id)),
            ),
          if (can.canChangeStatus)
            _ActionRow(
              key: const Key('changeStatus'),
              icon: Icons.schedule,
              label: l.changeStatus,
              onTap: () => context.push(RouteNames.changeStatus(a.id)),
            ),
          if (profile.can(Perms.incidentsCreate, projectId: session.projectId))
            _ActionRow(
              icon: Icons.warning_amber_rounded,
              label: l.reportIncident,
              onTap: () => context.push('${RouteNames.newIncident}?assetId=${a.id}'),
            ),
          if (profile.can(Perms.requirementsCreate, projectId: session.projectId))
            _ActionRow(
              icon: Icons.build_outlined,
              label: l.requestRepairOrWriteOff,
              onTap: () => context.push('${RouteNames.newRequirement}?assetId=${a.id}'),
            ),
        ];
        return FieldScaffold(
          title: model?.name ?? a.internalCode,
          above: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chapa(a.internalCode),
                if (inTransit)
                  StatusChip(l.inTransit, color: AppColors.statusMove, fontSize: 15)
                else
                  StatusChip(l.assetStatus(a.status), color: assetStatusColor(a.status), fontSize: 15),
                if (ctx.conditionName(a.conditionId) != null) StatusChip(ctx.conditionName(a.conditionId)!, fontSize: 15),
                if (a.openRemitoId != null) StatusChip(l.inOpenRemito, color: AppColors.statusMove, fontSize: 15),
                if (a.hasPendingChange) StatusChip(l.pendingSync, color: AppColors.statusWarning, fontSize: 15),
              ],
            ),
          subtitle: Text([
            if (brand != null) brand.name,
            if (custodian != null) l.inChargeOf(custodian),
          ].join(' · ')),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(l.whereIsIt, padTop: false),
                RuledList(
                  children: [
                    for (final (i, part) in chain.indexed)
                      Padding(
                        padding: EdgeInsets.fromLTRB(i * 18.0, 12, 0, 12),
                        child: Row(
                          children: [
                            if (i > 0) ...[
                              const Text('└', style: TextStyle(color: AppColors.textDisabled, fontSize: 16)),
                              const SizedBox(width: 8),
                            ],
                            Icon(_holderIcon(part.type), size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                switch (part.type) {
                                  HolderTypes.inTransit => l.inTransit,
                                  HolderTypes.employee => '${l.withPerson} ${part.name}'.trim(),
                                  _ => part.name,
                                },
                                style: TextStyle(fontSize: 16, fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (a.locationUpdatedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(l.sinceAgo(timeAgo(context, a.locationUpdatedAt!)),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ],
            ),
            Row(
              children: [
                CurrentPhoto(attachmentId: a.currentPhotoId, size: 88, height: 66, icon: Icons.photo_camera_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    a.currentPhotoId == null ? l.noCurrentPhoto : l.currentPhoto,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) RuledList(children: actions),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(l.details, padTop: false),
                _row(l.internalCode, a.internalCode, mono: true),
                if (a.manufacturerBarcode != null) _row(l.barcode, a.manufacturerBarcode!, mono: true),
                if (a.serialNumber != null) _row(l.serialNumber, a.serialNumber!, mono: true),
                if (a.licensePlate != null) _row(l.licensePlate, a.licensePlate!, mono: true),
                if (model != null) _row(l.category, l.assetCategory(model.category)),
                if (custodian != null) _row(l.custodian, custodian),
                if (a.description != null) _row(l.description, a.description!),
              ],
            ),
            if (contents.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.contents(contents.length), padTop: false),
                  DecoratedBox(
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.ink))),
                    child: Column(
                      children: [
                        for (final c in contents)
                          AssetTile(asset: c, ctx: ctx, onTap: () => context.push(RouteNames.itemDetail(c.id))),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  static IconData _holderIcon(String t) => switch (t) {
        HolderTypes.location => Icons.place_outlined,
        HolderTypes.asset => Icons.all_inbox_outlined,
        HolderTypes.employee => Icons.person_outline,
        _ => Icons.local_shipping_outlined,
      };

  static Widget _row(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(k, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                v,
                style: mono ? AppFonts.monoStyle(fontSize: 15, color: AppColors.ink) : const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RowLink(
        leading: Icon(icon, size: 22, color: context.brand.ink),
        title: label,
        onTap: onTap,
      );
}
