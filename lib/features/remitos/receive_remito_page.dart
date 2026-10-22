import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';
import '../checkins/on_site_guard.dart';
import '../items/item_lookup.dart';

/// Recepción de un remito ítem por ítem (v4 §9.5): recibido, faltante o
/// dañado (foto obligatoria). Los consumibles se confirman por cantidad.
class ReceiveRemitoPage extends StatefulWidget {
  const ReceiveRemitoPage({super.key, required this.remitoId});

  final String remitoId;

  @override
  State<ReceiveRemitoPage> createState() => _ReceiveRemitoPageState();
}

class _ReceiveRemitoPageState extends State<ReceiveRemitoPage> {
  Remito? _remito;
  ItemContext? _ctx;
  List<ReceptionLineInput> _lines = [];
  final _notes = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _showErrors = false;

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
    final repo = sl<FieldRepository>();
    final remito = await repo.remito(widget.remitoId);
    final items = await repo.remitoItems(widget.remitoId);
    final ctx = await ItemContext.load();
    if (!mounted) return;
    setState(() {
      _remito = remito;
      _ctx = ctx;
      _lines = [
        for (final i in items)
          ReceptionLineInput(
            item: i,
            quantityReceived: i.assetId == null ? i.quantitySent : null,
          ),
      ];
      _loading = false;
    });
  }

  bool get _valid => _lines.every((l) => l.result != ReceptionResult.damaged || l.photos.isNotEmpty);

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_valid) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.damagedNeedsPhoto)));
      return;
    }
    final missing = _lines.where((x) => x.result == ReceptionResult.missing).length;
    final damaged = _lines.where((x) => x.result == ReceptionResult.damaged).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.confirmReception),
        content: Text(l.receptionSummary(_lines.length - missing - damaged, missing, damaged)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const Key('confirmReceptionDialog'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (!await ensureOnSite(context, bypassPermissions: const [Perms.remitosWrite, Perms.remitosControl])) return;
    if (!mounted) return;
    setState(() => _saving = true);
    await sl<FieldActions>().receiveRemito(
      remito: _remito!,
      lines: _lines,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final maxPhotos = context.read<SessionCubit>().state.profile?.maxPhotosPerVerification ?? 5;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final r = _remito;
    final ctx = _ctx!;
    if (r == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off, text: l.remitoNotFound));
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.receiveRemitoTitle(r.displayNumber))),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Text(
            l.fromTo(ctx.locations[r.originId]?.name ?? '—', ctx.locations[r.destinationId]?.name ?? '—'),
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(l.receptionHelp, style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          for (final line in _lines) ...[
            _LineCard(
              line: line,
              ctx: ctx,
              maxPhotos: maxPhotos,
              showErrors: _showErrors,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.notesOptional),
          ),
          const LocalSaveHint(),
          FilledButton(
            key: const Key('confirmReception'),
            onPressed: _saving || _lines.isEmpty ? null : _submit,
            child: Text(l.confirmReception),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.ctx,
    required this.maxPhotos,
    required this.showErrors,
    required this.onChanged,
  });

  final ReceptionLineInput line;
  final ItemContext ctx;
  final int maxPhotos;
  final bool showErrors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = line.item;
    final asset = item.assetId == null ? null : ctx.assets[item.assetId];
    final model = ctx.models[asset?.modelId ?? item.modelId];
    final isBulk = item.assetId == null;
    final title = asset != null ? ctx.resolver.label(asset) : (model?.name ?? '—');
    return Card(
      key: Key('line-${asset?.internalCode ?? model?.name}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            if (isBulk)
              Text(
                [if (item.variant.isNotEmpty) item.variant, l.sentQuantity('${item.quantitySent}')].join(' · '),
                style: context.textTheme.bodySmall,
              ),
            const SizedBox(height: AppSizes.sm),
            SegmentedButton<ReceptionResult>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ReceptionResult.received, label: Text(l.markReceived), icon: const Icon(Icons.check)),
                ButtonSegment(value: ReceptionResult.missing, label: Text(l.markMissing), icon: const Icon(Icons.help_outline)),
                ButtonSegment(value: ReceptionResult.damaged, label: Text(l.markDamaged), icon: const Icon(Icons.broken_image_outlined)),
              ],
              selected: {line.result},
              onSelectionChanged: (s) {
                line.result = s.first;
                if (isBulk) {
                  line.quantityReceived = line.result == ReceptionResult.missing ? 0 : item.quantitySent;
                }
                onChanged();
              },
            ),
            if (isBulk && line.result != ReceptionResult.missing) ...[
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                initialValue: '${line.quantityReceived ?? item.quantitySent}',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(labelText: l.receivedQuantity, isDense: true),
                onChanged: (v) {
                  line.quantityReceived = num.tryParse(v);
                  onChanged();
                },
              ),
              if ((line.quantityReceived ?? 0) < item.quantitySent)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.lessThanSent, style: const TextStyle(color: AppColors.statusWarning)),
                ),
            ],
            if (line.result == ReceptionResult.damaged) ...[
              const SizedBox(height: AppSizes.sm),
              PhotoStrip(
                photos: line.photos,
                max: maxPhotos,
                required: true,
                showError: showErrors,
                onChanged: onChanged,
              ),
            ],
            if (line.result != ReceptionResult.received) ...[
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                initialValue: line.notes,
                decoration: InputDecoration(labelText: l.whatHappened, isDense: true),
                onChanged: (v) => line.notes = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
