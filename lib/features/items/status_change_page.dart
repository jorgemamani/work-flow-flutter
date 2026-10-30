import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import 'item_lookup.dart';

/// Cambiar el estado y/o la condición de un ítem (LOG-05). Es un hecho: no
/// se edita el ítem, se registra el cambio.
class StatusChangePage extends StatefulWidget {
  const StatusChangePage({super.key, required this.assetId});

  final String assetId;

  @override
  State<StatusChangePage> createState() => _StatusChangePageState();
}

class _StatusChangePageState extends State<StatusChangePage> {
  String? _status;
  String? _condition;
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save(Asset a) async {
    setState(() => _saving = true);
    await sl<FieldActions>().changeStatus(
      asset: a,
      toStatus: _status != a.status ? _status : null,
      toConditionId: _condition != a.conditionId ? _condition : null,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.changeStatus)),
      body: LiveQuery<ItemContext>(
        query: ItemContext.load,
        builder: (context, ctx) {
          final a = ctx.assets[widget.assetId];
          if (a == null) return EmptyState(icon: Icons.search_off, text: l.itemNotFound);
          _status ??= a.status;
          _condition ??= a.conditionId;
          final changed = _status != a.status || _condition != a.conditionId;
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              Text(ctx.resolver.label(a), style: context.textTheme.titleMedium),
              SectionTitle(l.status),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  for (final s in AssetStatuses.all)
                    ChoiceChip(
                      key: Key('status-$s'),
                      label: Text(l.assetStatus(s)),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                ],
              ),
              if (ctx.conditions.isNotEmpty) ...[
                SectionTitle(l.condition),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final c in ctx.conditions)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _condition == c.id,
                        onSelected: (_) => setState(() => _condition = c.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              TextField(
                controller: _reason,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.reasonOptional),
              ),
              const LocalSaveHint(),
              FilledButton(
                key: const Key('saveStatus'),
                onPressed: !changed || _saving ? null : () => _save(a),
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
