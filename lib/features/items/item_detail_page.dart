import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/profile.dart';
import '../../core/data/models.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../../shared/widgets/sync_indicator.dart';
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
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(icon: Icons.search_off, text: l.itemNotFound),
          );
        }
        final model = ctx.models[a.modelId];
        final brand = ctx.brands[model?.brandId];
        final inProject = a.effectiveProjectId != null && a.effectiveProjectId == session.projectId;
        final mineOrProject = inProject ||
            (a.holderType == HolderTypes.employee && a.holderId == profile.employeeId);
        final canMove = mineOrProject &&
            a.holderType != HolderTypes.inTransit &&
            a.openRemitoId == null &&
            profile.can(Perms.moveWithinProject, projectId: session.projectId);
        final contents = ctx.contents(a);
        return Scaffold(
          appBar: AppBar(
            title: Text(a.internalCode),
            actions: const [SyncIndicator()],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: LayoutBuilder(
                  builder: (context, c) => CurrentPhoto(
                    attachmentId: a.currentPhotoId,
                    size: c.maxWidth,
                    icon: Icons.photo_outlined,
                  ),
                ),
              ),
              if (a.currentPhotoId == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(l.noCurrentPhoto, style: context.textTheme.bodySmall),
                ),
              const SizedBox(height: AppSizes.md),
              Text(
                model?.name ?? '',
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (brand != null) Text(brand.name, style: context.textTheme.bodyMedium),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.xs,
                children: [
                  StatusChip(l.assetStatus(a.status), color: assetStatusColor(a.status)),
                  if (ctx.conditionName(a.conditionId) != null)
                    StatusChip(ctx.conditionName(a.conditionId)!, icon: Icons.star_outline),
                  if (a.openRemitoId != null)
                    StatusChip(l.inOpenRemito, color: AppColors.statusWarning, icon: Icons.local_shipping_outlined),
                  if (a.hasPendingChange)
                    StatusChip(l.pendingSync, color: AppColors.primary),
                ],
              ),
              SectionTitle(l.whereIsIt),
              Card(
                child: ListTile(
                  leading: Icon(_holderIcon(a.holderType)),
                  title: Text(ctx.where(a, inTransit: l.inTransit, withPerson: l.withPerson)),
                  subtitle: a.locationUpdatedAt == null
                      ? null
                      : Text(l.sinceAgo(timeAgo(context, a.locationUpdatedAt!))),
                ),
              ),
              SectionTitle(l.details),
              Card(
                child: Column(
                  children: [
                    _row(l.internalCode, a.internalCode),
                    if (a.manufacturerBarcode != null) _row(l.barcode, a.manufacturerBarcode!),
                    if (a.serialNumber != null) _row(l.serialNumber, a.serialNumber!),
                    if (a.licensePlate != null) _row(l.licensePlate, a.licensePlate!),
                    if (model != null) _row(l.category, model.category),
                    if (a.custodianEmployeeId != null)
                      _row(l.custodian, ctx.employees[a.custodianEmployeeId]?.fullName ?? '—'),
                    if (a.description != null) _row(l.description, a.description!),
                  ],
                ),
              ),
              if (contents.isNotEmpty) ...[
                SectionTitle(l.contents(contents.length)),
                for (final c in contents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: AssetTile(
                      asset: c,
                      ctx: ctx,
                      onTap: () => context.push(RouteNames.itemDetail(c.id)),
                    ),
                  ),
              ],
              const SizedBox(height: AppSizes.lg),
              if (canMove) ...[
                FilledButton.icon(
                  key: const Key('moveItem'),
                  icon: const Icon(Icons.open_with),
                  label: Text(l.moveItem),
                  onPressed: () => context.push(RouteNames.moveItem(a.id)),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
              if (mineOrProject)
                OutlinedButton.icon(
                  key: const Key('changeStatus'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.tune),
                  label: Text(l.changeStatus),
                  onPressed: () => context.push(RouteNames.changeStatus(a.id)),
                ),
              const SizedBox(height: AppSizes.sm),
              if (profile.can(Perms.incidentsCreate, projectId: session.projectId))
                TextButton.icon(
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(l.reportIncident),
                  onPressed: () => context.push('${RouteNames.newIncident}?assetId=${a.id}'),
                ),
              if (profile.can(Perms.requirementsCreate, projectId: session.projectId))
                TextButton.icon(
                  icon: const Icon(Icons.build_outlined),
                  label: Text(l.requestRepairOrWriteOff),
                  onPressed: () => context.push('${RouteNames.newRequirement}?assetId=${a.id}'),
                ),
            ],
          ),
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

  static Widget _row(String k, String v) => ListTile(
        dense: true,
        title: Text(k),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(v, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
        ),
      );
}
