import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../auth/presentation/session_cubit.dart';
import '../items/item_lookup.dart';

/// Remito de devolución armado en el proyecto, sin señal (v4 §9.4).
class ReturnRemitoPage extends StatefulWidget {
  const ReturnRemitoPage({super.key});

  @override
  State<ReturnRemitoPage> createState() => _ReturnRemitoPageState();
}

class _ReturnRemitoPageState extends State<ReturnRemitoPage> {
  ItemContext? _ctx;
  List<Asset> _assets = [];
  List<StockBalance> _stock = [];
  String? _origin;
  String? _destination;
  final _selected = <String>{};
  final _quantities = <String, num>{};
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final projectId = context.read<SessionCubit>().state.projectId;
    if (projectId == null) return;
    final repo = sl<FieldRepository>();
    final ctx = await ItemContext.load();
    final project = await repo.project(projectId);
    final assets = [
      for (final a in await repo.projectAssets(projectId))
        if (a.openRemitoId == null && a.holderType == 'LOCATION') a,
    ]..sort((a, b) => a.internalCode.compareTo(b.internalCode));
    final stock = [
      for (final s in await repo.projectStock(projectId))
        if (s.holderType == 'LOCATION') s,
    ];
    if (!mounted) return;
    setState(() {
      _ctx = ctx;
      _assets = assets;
      _stock = stock;
      _origin = project?.rootLocationId;
      final warehouses = _warehouses(ctx);
      _destination = warehouses.isEmpty ? null : warehouses.first.id;
    });
  }

  List<Location> _warehouses(ItemContext ctx) => [
        for (final l in ctx.locations.values)
          if (l.projectId == null && l.type == 'WAREHOUSE' && l.isActive) l,
      ]..sort((a, b) => a.name.compareTo(b.name));

  Future<void> _save() async {
    final lines = <ReturnLineInput>[
      for (final a in _assets)
        if (_selected.contains(a.id)) ReturnLineInput(assetId: a.id),
      for (final s in _stock)
        if ((_quantities[s.id] ?? 0) > 0)
          ReturnLineInput(modelId: s.modelId, variant: s.variant, quantity: _quantities[s.id]),
    ];
    if (lines.isEmpty || _origin == null || _destination == null) return;
    setState(() => _saving = true);
    await sl<FieldActions>().returnRemito(
      originLocationId: _origin!,
      destinationLocationId: _destination!,
      projectId: context.read<SessionCubit>().state.projectId,
      lines: lines,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ctx = _ctx;
    if (ctx == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final projectId = context.watch<SessionCubit>().state.projectId;
    final origins = [
      for (final loc in ctx.locations.values)
        if (loc.projectId == projectId) loc,
    ];
    final count = _selected.length + _quantities.values.where((q) => q > 0).length;
    return Scaffold(
      appBar: AppBar(title: Text(l.returnRemitoTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _origin,
            decoration: InputDecoration(labelText: l.origin),
            items: [
              for (final o in origins) DropdownMenuItem(value: o.id, child: Text(o.name)),
            ],
            onChanged: (v) => setState(() => _origin = v),
          ),
          const SizedBox(height: AppSizes.md),
          DropdownButtonFormField<String>(
            initialValue: _destination,
            decoration: InputDecoration(labelText: l.destinationWarehouse),
            items: [
              for (final w in _warehouses(ctx)) DropdownMenuItem(value: w.id, child: Text(w.name)),
            ],
            onChanged: (v) => setState(() => _destination = v),
          ),
          SectionTitle(l.itemsToReturn),
          if (_assets.isEmpty && _stock.isEmpty)
            EmptyState(icon: Icons.inventory_2_outlined, text: l.noProjectItems),
          for (final a in _assets)
            CheckboxListTile(
              value: _selected.contains(a.id),
              onChanged: (v) => setState(() => v == true ? _selected.add(a.id) : _selected.remove(a.id)),
              title: Text(ctx.resolver.label(a)),
              subtitle: Text(ctx.where(a, inTransit: l.inTransit, withPerson: l.withPerson)),
              secondary: StatusChip(l.assetStatus(a.status), color: assetStatusColor(a.status)),
            ),
          if (_stock.isNotEmpty) SectionTitle(l.consumables),
          for (final s in _stock)
            ListTile(
              title: Text(ctx.models[s.modelId]?.name ?? ''),
              subtitle: Text([if (s.variant.isNotEmpty) s.variant, l.available('${s.quantity}')].join(' · ')),
              trailing: SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(isDense: true, hintText: '0'),
                  onChanged: (v) => setState(() {
                    final q = num.tryParse(v) ?? 0;
                    _quantities[s.id] = q > s.quantity ? s.quantity : q;
                  }),
                ),
              ),
            ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.notesOptional),
          ),
          const LocalSaveHint(),
          FilledButton(
            onPressed: count == 0 || _saving || _destination == null ? null : _save,
            child: Text(l.createReturn(count)),
          ),
        ],
      ),
    );
  }
}
