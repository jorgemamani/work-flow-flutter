import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_actions.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../auth/presentation/session_cubit.dart';
import '../checkins/on_site_guard.dart';
import 'item_lookup.dart';

class _Dest {
  const _Dest(this.type, this.id, this.label, this.icon, {this.effectiveLocationId, this.subtitle});

  final String type;
  final String id;
  final String label;
  final String? subtitle;
  final IconData icon;
  final String? effectiveLocationId;

  String get key => '$type:$id';
}

/// Mover un ítem dentro del proyecto (RN-02): a otra ubicación, adentro de
/// un contenedor o vehículo (D17), o a mi cargo.
class MoveItemPage extends StatefulWidget {
  const MoveItemPage({super.key, required this.assetId});

  final String assetId;

  @override
  State<MoveItemPage> createState() => _MoveItemPageState();
}

class _MoveItemPageState extends State<MoveItemPage> {
  _Dest? _selected;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<_Dest> _destinations(BuildContext context, ItemContext ctx, Asset asset, String projectId, String? employeeId) {
    final l = context.l10n;
    // Un contenedor no puede ir adentro de sí mismo ni de su contenido.
    final excluded = <String>{asset.id};
    var grew = true;
    while (grew) {
      grew = false;
      for (final x in ctx.assets.values) {
        if (x.holderType == HolderTypes.asset && excluded.contains(x.holderId) && excluded.add(x.id)) {
          grew = true;
        }
      }
    }
    final locations = [
      for (final loc in ctx.locations.values)
        if (loc.projectId == projectId && loc.isActive)
          _Dest(HolderTypes.location, loc.id, loc.name, Icons.place_outlined,
              effectiveLocationId: loc.id, subtitle: l.locationType(loc.type)),
    ]..sort((a, b) => a.label.compareTo(b.label));
    final containers = [
      for (final x in ctx.assets.values)
        if (x.effectiveProjectId == projectId &&
            !excluded.contains(x.id) &&
            ((ctx.models[x.modelId]?.isContainer ?? false) || (ctx.models[x.modelId]?.isVehicle ?? false)))
          _Dest(HolderTypes.asset, x.id, ctx.resolver.label(x),
              (ctx.models[x.modelId]?.isVehicle ?? false) ? Icons.local_shipping_outlined : Icons.all_inbox_outlined,
              effectiveLocationId: x.effectiveLocationId,
              subtitle: ctx.where(x, inTransit: l.inTransit, withPerson: l.withPerson)),
    ]..sort((a, b) => a.label.compareTo(b.label));
    return [
      ...locations,
      ...containers,
      if (employeeId != null) _Dest(HolderTypes.employee, employeeId, l.toMyCharge, Icons.back_hand_outlined),
    ];
  }

  Future<void> _save(Asset asset) async {
    final d = _selected;
    if (d == null) return;
    if (!await ensureOnSite(context, bypassPermissions: const [Perms.inventoryMove])) return;
    if (!mounted) return;
    setState(() => _saving = true);
    await sl<FieldActions>().moveAsset(
      asset: asset,
      toHolderType: d.type,
      toHolderId: d.id,
      effectiveLocationId: d.effectiveLocationId,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l.moveItem)),
      body: LiveQuery<ItemContext>(
        query: ItemContext.load,
        builder: (context, ctx) {
          final asset = ctx.assets[widget.assetId];
          if (asset == null || session.projectId == null) {
            return EmptyState(icon: Icons.search_off, text: l.itemNotFound);
          }
          final dests = _destinations(context, ctx, asset, session.projectId!, session.profile?.employeeId);
          final current = '${asset.holderType}:${asset.holderId}';
          return Column(
            children: [
              ListTile(
                title: Text(ctx.resolver.label(asset), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l.nowAt(ctx.where(asset, inTransit: l.inTransit, withPerson: l.withPerson))),
              ),
              const Divider(height: 1),
              Expanded(
                child: RadioGroup<String>(
                  groupValue: _selected?.key,
                  onChanged: (v) => setState(() => _selected = dests.firstWhere((d) => d.key == v)),
                  child: ListView(
                    children: [
                      for (final d in dests)
                        RadioListTile<String>(
                          key: Key('dest-${d.label}'),
                          value: d.key,
                          enabled: d.key != current,
                          secondary: Icon(d.icon),
                          title: Text(d.label),
                          subtitle: d.subtitle == null ? null : Text(d.subtitle!),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: [
                      TextField(
                        controller: _notes,
                        decoration: InputDecoration(labelText: l.notesOptional, isDense: true),
                      ),
                      const LocalSaveHint(),
                      FilledButton(
                        key: const Key('confirmMove'),
                        onPressed: _selected == null || _saving ? null : () => _save(asset),
                        child: Text(l.confirmMove),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
