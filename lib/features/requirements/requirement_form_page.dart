import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../auth/presentation/session_cubit.dart';
import '../items/item_lookup.dart';
import '../items/scan_page.dart';

class _Line {
  _Line({this.model, this.asset, this.variant, this.description});

  AssetModel? model;
  Asset? asset;
  String? variant;
  num quantity = 1;
  String? description;
}

/// Solicitud (REP-04 / D19): pedir ítems nuevos, o bajas y reparaciones de
/// ítems del proyecto.
class RequirementFormPage extends StatefulWidget {
  const RequirementFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  State<RequirementFormPage> createState() => _RequirementFormPageState();
}

class _RequirementFormPageState extends State<RequirementFormPage> {
  static const _kinds = ['NEW_ITEMS', 'REPAIR', 'WRITE_OFF'];

  ItemContext? _ctx;
  String _kind = 'NEW_ITEMS';
  final _lines = <_Line>[];
  final _notes = TextEditingController();
  DateTime? _neededBy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ItemContext.load().then((ctx) {
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        final a = widget.assetId == null ? null : ctx.assets[widget.assetId];
        if (a != null) {
          _kind = 'REPAIR';
          _lines.add(_Line(asset: a));
        }
      });
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addModel() async {
    final ctx = _ctx!;
    final models = ctx.models.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    final m = await showModalBottomSheet<AssetModel>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.7,
          child: ListView(
            children: [
              for (final m in models)
                ListTile(title: Text(m.name), subtitle: Text(context.l10n.assetCategory(m.category)), onTap: () => Navigator.pop(c, m)),
            ],
          ),
        ),
      ),
    );
    if (m != null) {
      setState(() => _lines.add(_Line(model: m, variant: m.variants.isEmpty ? null : m.variants.first)));
    }
  }

  void _addFreeText() => setState(() => _lines.add(_Line(description: '')));

  Future<void> _addAsset() async {
    final a = await Navigator.of(context).push<Asset>(
      MaterialPageRoute(builder: (_) => const ScanPage(pickOnly: true)),
    );
    if (a != null) setState(() => _lines.add(_Line(asset: a)));
  }

  bool get _valid =>
      _lines.isNotEmpty &&
      _lines.every((x) => x.model != null || x.asset != null || (x.description?.trim().isNotEmpty ?? false));

  Future<void> _save() async {
    setState(() => _saving = true);
    await sl<FieldActions>().submitRequirement(
      projectId: context.read<SessionCubit>().state.projectId!,
      kind: _kind,
      notes: _notes.text.trim(),
      neededBy: _neededBy == null ? null : DateFormat('yyyy-MM-dd').format(_neededBy!),
      items: [
        for (final x in _lines)
          RequirementItemInput(
            modelId: x.model?.id,
            assetId: x.asset?.id,
            variant: x.variant,
            quantity: x.asset != null ? 1 : x.quantity,
            description: x.description,
          ),
      ],
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
    final forAssets = _kind != 'NEW_ITEMS';
    return Scaffold(
      appBar: AppBar(title: Text(l.actionRequirement)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          SegmentedButton<String>(
            segments: [for (final k in _kinds) ButtonSegment(value: k, label: Text(l.requirementKind(k)))],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _lines.clear();
            }),
          ),
          SectionTitle(l.itemsCount(_lines.length)),
          for (final x in _lines)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: x.description != null && x.model == null && x.asset == null
                              ? TextFormField(
                                  initialValue: x.description,
                                  decoration: InputDecoration(labelText: l.describeItem, isDense: true),
                                  onChanged: (v) => setState(() => x.description = v),
                                )
                              : Text(
                                  x.asset != null ? ctx.resolver.label(x.asset!) : x.model!.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _lines.remove(x))),
                      ],
                    ),
                    if (x.asset == null)
                      Row(
                        children: [
                          if (x.model != null && x.model!.variants.isNotEmpty)
                            DropdownButton<String>(
                              value: x.variant,
                              items: [for (final v in x.model!.variants) DropdownMenuItem(value: v, child: Text(v))],
                              onChanged: (v) => setState(() => x.variant = v),
                            ),
                          const Spacer(),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: '${x.quantity}',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(labelText: l.quantity, isDense: true),
                              onChanged: (v) => x.quantity = num.tryParse(v) ?? 1,
                            ),
                          ),
                        ],
                      )
                    else
                      TextFormField(
                        initialValue: x.description,
                        decoration: InputDecoration(labelText: l.whatHappened, isDense: true),
                        onChanged: (v) => x.description = v,
                      ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              if (forAssets)
                OutlinedButton.icon(onPressed: _addAsset, icon: const Icon(Icons.qr_code_scanner), label: Text(l.addProjectItem))
              else ...[
                OutlinedButton.icon(onPressed: _addModel, icon: const Icon(Icons.list), label: Text(l.fromCatalog)),
                OutlinedButton.icon(onPressed: _addFreeText, icon: const Icon(Icons.edit), label: Text(l.otherItem)),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(_neededBy == null ? l.neededByOptional : DateFormat.yMMMd().format(_neededBy!)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: _neededBy ?? DateTime.now().add(const Duration(days: 7)),
              );
              if (d != null) setState(() => _neededBy = d);
            },
          ),
          TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l.notesOptional)),
          const LocalSaveHint(),
          FilledButton(onPressed: !_valid || _saving ? null : _save, child: Text(l.send)),
        ],
      ),
    );
  }
}
