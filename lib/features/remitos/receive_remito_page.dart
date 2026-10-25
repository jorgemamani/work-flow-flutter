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
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/photo_strip.dart';
import '../../shared/widgets/tenant_mark.dart';
import '../auth/presentation/session_cubit.dart';
import '../checkins/on_site_guard.dart';
import '../items/item_lookup.dart';
import '../items/scan_page.dart';

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

  /// Ítems con número de serie que ya se marcaron (los consumibles se
  /// cuentan por cantidad y arrancan revisados).
  final _reviewed = <int>{};

  bool _isBulk(ReceptionLineInput x) => x.item.assetId == null;

  bool _isReviewed(int i) => _isBulk(_lines[i]) || _reviewed.contains(i);

  int get _done => [for (var i = 0; i < _lines.length; i++) if (_isReviewed(i)) i].length;

  bool _hasDifference(ReceptionLineInput x) => _isBulk(x)
      ? (x.quantityReceived ?? 0) < x.item.quantitySent
      : x.result != ReceptionResult.received;

  int get _differences => [
        for (var i = 0; i < _lines.length; i++)
          if (_isReviewed(i) && _hasDifference(_lines[i])) i,
      ].length;

  bool get _valid => _lines.every((l) => l.result != ReceptionResult.damaged || l.photos.isNotEmpty);

  void _mark(int i, ReceptionResult? r) => setState(() {
        if (r == null) {
          _reviewed.remove(i);
          _lines[i].result = ReceptionResult.received;
        } else {
          _reviewed.add(i);
          _lines[i].result = r;
        }
      });

  /// Escanear un ítem del remito lo marca como recibido.
  Future<void> _scan() async {
    final l = context.l10n;
    final a = await Navigator.of(context).push<Asset>(
      MaterialPageRoute(builder: (_) => const ScanPage(pickOnly: true)),
    );
    if (a == null || !mounted) return;
    final i = _lines.indexWhere((x) => x.item.assetId == a.id);
    if (i < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.notInRemito(a.internalCode))));
      return;
    }
    _mark(i, ReceptionResult.received);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_valid) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.damagedNeedsPhoto)));
      return;
    }
    for (final x in _lines) {
      if (_isBulk(x)) x.result = (x.quantityReceived ?? 0) <= 0 ? ReceptionResult.missing : ReceptionResult.received;
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
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
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
      return FieldScaffold(body: EmptyState(icon: Icons.search_off, text: l.remitoNotFound));
    }
    final total = _lines.length;
    final left = total - _done;
    final diffs = _differences;
    return FieldScaffold(
      topTrailing: const TenantMark(showName: true),
      title: l.receiveTitle,
      titleBadge: Chapa(r.displayNumber),
      subtitle: Text(l.fromTo(ctx.locations[r.originId]?.name ?? '—', ctx.locations[r.destinationId]?.name ?? '—')),
      headerBottom: ProgressHeader(
        label: l.reviewedOf(_done, total),
        trailing: l.differencesCount(diffs),
        value: total == 0 ? 0 : _done / total,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
        children: [
          AppButton(
            label: l.scanToMark,
            isOutlined: true,
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            onPressed: _scan,
          ),
          const SizedBox(height: AppSizes.md),
          RuledList(
            children: [
              for (final (i, line) in _lines.indexed)
                _LineTile(
                  line: line,
                  ctx: ctx,
                  reviewed: _isReviewed(i),
                  maxPhotos: maxPhotos,
                  showErrors: _showErrors,
                  onMark: (res) => _mark(i, res),
                  onChanged: () => setState(() {}),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          FieldLabel(
            l.notesOptional,
            child: TextField(controller: _notes, maxLines: 2),
          ),
        ],
      ),
      footer: FieldFooter(
        hint: left > 0 ? l.markEachItem : l.sentWhenSignal,
        children: [
          AppButton(
            key: const Key('confirmReception'),
            label: left > 0 ? l.leftToReview(left) : (diffs > 0 ? l.confirmWithDifferences : l.confirmReception),
            isLoading: _saving,
            onPressed: left > 0 || _lines.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.ctx,
    required this.reviewed,
    required this.maxPhotos,
    required this.showErrors,
    required this.onMark,
    required this.onChanged,
  });

  final ReceptionLineInput line;
  final ItemContext ctx;
  final bool reviewed;
  final int maxPhotos;
  final bool showErrors;
  final ValueChanged<ReceptionResult?> onMark;
  final VoidCallback onChanged;

  static String _qty(num n) => n == n.roundToDouble() ? '${n.toInt()}' : '$n';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = line.item;
    final asset = item.assetId == null ? null : ctx.assets[item.assetId];
    final model = ctx.models[asset?.modelId ?? item.modelId];
    final isBulk = item.assetId == null;
    final received = line.quantityReceived ?? item.quantitySent;
    final short = isBulk && received < item.quantitySent;
    final (String state, Color color) = isBulk
        ? (short ? (l.withDifference, AppColors.statusWarning) : (l.markReceived, AppColors.statusSuccess))
        : !reviewed
            ? (l.notReviewed, AppColors.statusNeutral)
            : switch (line.result) {
                ReceptionResult.received => (l.markReceived, AppColors.statusSuccess),
                ReceptionResult.missing => (l.markMissing, AppColors.statusError),
                ReceptionResult.damaged => (l.markDamaged, AppColors.statusWarning),
              };
    final code = asset?.internalCode ??
        [if (item.variant.isNotEmpty) item.variant, l.sentQuantity(_qty(item.quantitySent))].join(' · ');
    return Padding(
      key: Key('line-${asset?.internalCode ?? model?.name}'),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model?.name ?? '—', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(code, style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(state, color: color),
            ],
          ),
          const SizedBox(height: 12),
          if (isBulk) ...[
            _Stepper(
              value: received,
              max: item.quantitySent,
              unit: model?.unitOfMeasure == null ? l.unitsReceived : '${model!.unitOfMeasure} · ${l.unitsReceived}',
              onChanged: (v) {
                line.quantityReceived = v;
                onChanged();
              },
            ),
            if (short) ...[
              const SizedBox(height: 10),
              Text(l.shortBy(_qty(item.quantitySent - received)),
                  style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.statusWarning)),
            ],
          ] else
            ChoiceGrid<ReceptionResult>(
              semanticLabel: l.howItArrived,
              columns: 3,
              height: 48,
              allowNone: true,
              selected: reviewed ? line.result : null,
              onChanged: onMark,
              options: [
                ChoiceOption(ReceptionResult.received, l.optArrived),
                ChoiceOption(ReceptionResult.missing, l.optMissing),
                ChoiceOption(ReceptionResult.damaged, l.optDamaged),
              ],
            ),
          if (reviewed && line.result == ReceptionResult.damaged) ...[
            const SizedBox(height: 12),
            Text(l.damagePhotoRequired, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            PhotoStrip(
              photos: line.photos,
              max: maxPhotos,
              required: true,
              showError: showErrors,
              onChanged: onChanged,
            ),
          ],
          if (reviewed && line.result != ReceptionResult.received) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: line.notes,
              decoration: InputDecoration(hintText: l.whatHappened),
              onChanged: (v) => line.notes = v,
            ),
          ],
        ],
      ),
    );
  }
}

/// − cantidad + con botones de 56. Tocar el número deja escribirlo.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.max, required this.unit, required this.onChanged});

  final num value;
  final num max;
  final String unit;
  final ValueChanged<num> onChanged;

  Future<void> _type(BuildContext context) async {
    final v = await showDialog<num>(
      context: context,
      builder: (_) => _QtyDialog(initial: _LineTile._qty(value)),
    );
    if (v != null) onChanged(v.clamp(0, max));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget btn(String label, String tooltip, VoidCallback? onTap) => SizedBox(
          width: AppSizes.buttonHeight,
          height: AppSizes.buttonHeight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(AppSizes.buttonHeight),
              textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            ),
            onPressed: onTap,
            child: Semantics(label: tooltip, child: Text(label)),
          ),
        );
    return Row(
      children: [
        btn('−', l.oneLess, value <= 0 ? null : () => onChanged((value - 1).clamp(0, max))),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: () => _type(context),
              child: SizedBox(
                height: AppSizes.buttonHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_LineTile._qty(value),
                        style: AppFonts.monoStyle(fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(unit,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        btn('+', l.oneMore, value >= max ? null : () => onChanged((value + 1).clamp(0, max))),
      ],
    );
  }
}

/// Escribir la cantidad recibida (consumibles con decimales).
class _QtyDialog extends StatefulWidget {
  const _QtyDialog({required this.initial});

  final String initial;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.receivedQuantity),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: AppFonts.monoStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.ink),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
          onPressed: () => Navigator.pop(context, num.tryParse(_controller.text)),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
