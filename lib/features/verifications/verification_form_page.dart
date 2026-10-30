import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../core/photos/photo_service.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/theme/tenant_brand.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';
import '../items/item_lookup.dart';

/// Verificación con fotos (REP-03, v4 §9.3 paso 8-9): un renglón por ítem,
/// con la condición observada y fotos. Respeta "requiere foto" del modelo y
/// el límite (de la programación o de la empresa, máximo 10).
class VerificationFormPage extends StatefulWidget {
  const VerificationFormPage({super.key});

  @override
  State<VerificationFormPage> createState() => _VerificationFormPageState();
}

class _VerificationFormPageState extends State<VerificationFormPage> {
  ItemContext? _ctx;
  List<Asset> _candidates = [];
  List<VerificationSchedule> _schedules = [];
  VerificationSchedule? _schedule;
  final _lines = <VerificationLineInput>[];
  final _notes = TextEditingController();
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
    final projectId = context.read<SessionCubit>().state.projectId;
    if (projectId == null) return;
    final repo = sl<FieldRepository>();
    final ctx = await ItemContext.load();
    final candidates = [
      for (final a in await repo.projectAssets(projectId))
        if (a.holderType != 'IN_TRANSIT') a,
    ]..sort((a, b) => a.internalCode.compareTo(b.internalCode));
    final schedules = await repo.schedules(projectId);
    if (!mounted) return;
    setState(() {
      _ctx = ctx;
      _candidates = candidates;
      _schedules = schedules;
    });
  }

  int _limit(BuildContext context) {
    final company = context.read<SessionCubit>().state.profile?.maxPhotosPerVerification ?? 5;
    return (_schedule?.photosPerItem ?? company).clamp(1, 10);
  }

  bool _requiresPhoto(Asset a) => _ctx?.models[a.modelId]?.requiresPhoto ?? false;

  Future<void> _addItems() async {
    final l = context.l10n;
    final ctx = _ctx!;
    final chosen = {for (final x in _lines) x.asset.id};
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _PickAssets(
        title: l.chooseItemsToVerify,
        assets: _candidates,
        ctx: ctx,
        initial: chosen,
      ),
    );
    if (picked == null) return;
    setState(() {
      _lines.removeWhere((x) => !picked.contains(x.asset.id));
      for (final a in _candidates) {
        if (picked.contains(a.id) && !chosen.contains(a.id)) {
          _lines.add(VerificationLineInput(asset: a, conditionId: a.conditionId));
        }
      }
    });
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final limit = _limit(context);
    final missing = _lines.where((x) => _requiresPhoto(x.asset) && x.photos.isEmpty).toList();
    final over = _lines.where((x) => x.photos.length > limit).toList();
    if (missing.isNotEmpty || over.isNotEmpty) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(missing.isNotEmpty ? l.verificationMissingPhotos(missing.length) : l.photosOverLimit(limit))),
      );
      return;
    }
    setState(() => _saving = true);
    await sl<FieldActions>().submitVerification(
      projectId: context.read<SessionCubit>().state.projectId!,
      scheduleId: _schedule?.id,
      lines: _lines,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  /// Un toque: cámara directa (con guantes no hay menú de por medio).
  Future<void> _quickPhoto(VerificationLineInput line) async {
    if (line.photos.length >= _limit(context)) return;
    final photo = await sl<PhotoService>().take(fromCamera: true);
    if (photo == null || !mounted) return;
    setState(() => line.photos.add(photo));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ctx = _ctx;
    if (ctx == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final limit = _limit(context);
    final withPhoto = _lines.where((x) => x.photos.isNotEmpty).length;
    final missing = _lines.where((x) => _requiresPhoto(x.asset) && x.photos.isEmpty).length;
    final due = _schedule?.nextDueAt;
    return FieldScaffold(
      title: _schedule?.name ?? l.actionVerification,
      subtitle: Text([
        l.photoLimitInfo(limit),
        if (due != null) l.dueOnShort(DateFormat('dd/MM').format(due.toLocal())),
      ].join(' · ')),
      headerBottom: _lines.isEmpty
          ? null
          : ProgressHeader(
              label: l.photosDoneOf(withPhoto, _lines.length),
              value: withPhoto / _lines.length,
            ),
      footer: FieldFooter(
        hint: missing > 0 ? l.verificationMissingPhotos(missing) : l.sentWhenSignalShort,
        children: [
          AppButton(
            key: const Key('submitVerification'),
            label: l.submitVerification,
            isLoading: _saving,
            onPressed: _lines.isEmpty ? null : _submit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.lg),
        children: [
          if (_schedules.isNotEmpty) ...[
            FieldLabel(
              l.scheduleOptional,
              child: DropdownButtonFormField<String?>(
                initialValue: _schedule?.id,
                items: [
                  DropdownMenuItem(value: null, child: Text(l.noSchedule)),
                  for (final s in _schedules) DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() {
                  _schedule = v == null ? null : _schedules.firstWhere((s) => s.id == v);
                }),
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          AppButton(
            key: const Key('addVerificationItems'),
            label: _lines.isEmpty ? l.chooseItems : l.itemsCount(_lines.length),
            isOutlined: true,
            icon: const Icon(Icons.playlist_add, size: 22),
            onPressed: _addItems,
          ),
          const SizedBox(height: AppSizes.md),
          if (_lines.isEmpty)
            EmptyState(icon: Icons.photo_camera_outlined, text: l.verificationEmpty)
          else
            RuledList(
              children: [
                for (final line in _lines)
                  _VLine(
                    key: Key('vline-${line.asset.internalCode}'),
                    line: line,
                    ctx: ctx,
                    limit: limit,
                    requiresPhoto: _requiresPhoto(line.asset),
                    showErrors: _showErrors,
                    onQuickPhoto: () => _quickPhoto(line),
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
          if (_lines.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l.verificationPhotosNote, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.md),
            FieldLabel(l.generalNotes, child: TextField(controller: _notes, maxLines: 2)),
          ],
        ],
      ),
    );
  }
}

/// Un ítem: nombre, código y el botón de cámara (en el color de la empresa cuando ya tiene
/// foto). Abajo, plegado, la condición, más fotos y notas.
class _VLine extends StatefulWidget {
  const _VLine({
    super.key,
    required this.line,
    required this.ctx,
    required this.limit,
    required this.requiresPhoto,
    required this.showErrors,
    required this.onQuickPhoto,
    required this.onChanged,
  });

  final VerificationLineInput line;
  final ItemContext ctx;
  final int limit;
  final bool requiresPhoto;
  final bool showErrors;
  final VoidCallback onQuickPhoto;
  final VoidCallback onChanged;

  @override
  State<_VLine> createState() => _VLineState();
}

class _VLineState extends State<_VLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final line = widget.line;
    final name = widget.ctx.modelName(line.asset);
    final done = line.photos.isNotEmpty;
    final warn = widget.requiresPhoto && !done && widget.showErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _open = !_open),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isEmpty ? line.asset.internalCode : name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(line.asset.internalCode,
                                style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary)),
                            if (widget.requiresPhoto && !done)
                              StatusChip(l.requiresPhoto,
                                  color: warn ? AppColors.statusError : AppColors.statusWarning, fontSize: 13),
                            if (line.photos.length > 1)
                              Text(l.photosCount(line.photos.length, widget.limit),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: done ? l.photoReadyOf(name) : l.takePhotoOf(name),
                  excludeSemantics: true,
                  child: Material(
                    color: done ? context.brand.fill : AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: done
                          ? BorderSide.none
                          : BorderSide(color: warn ? AppColors.statusError : context.brand.ink, width: 1.5),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onQuickPhoto,
                      child: SizedBox(
                        width: 64,
                        height: AppSizes.buttonHeight,
                        child: Icon(
                          done ? Icons.check : Icons.photo_camera_outlined,
                          size: 24,
                          color: done ? context.brand.on : context.brand.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_open)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 14, decoration: TextDecoration.underline),
              ),
              onPressed: () => setState(() => _open = true),
              child: Text(l.showDetails),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.ctx.conditions.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in widget.ctx.conditions)
                        ChoiceChip(
                          label: Text(c.name),
                          selected: line.conditionId == c.id,
                          onSelected: (_) {
                            line.conditionId = c.id;
                            widget.onChanged();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                PhotoStrip(
                  photos: line.photos,
                  max: widget.limit,
                  required: widget.requiresPhoto,
                  showError: widget.showErrors,
                  onChanged: widget.onChanged,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: line.notes,
                  decoration: InputDecoration(hintText: l.notesOptional),
                  onChanged: (v) => line.notes = v,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Elegir varios ítems de una lista con búsqueda.
class _PickAssets extends StatefulWidget {
  const _PickAssets({
    required this.title,
    required this.assets,
    required this.ctx,
    required this.initial,
  });

  final String title;
  final List<Asset> assets;
  final ItemContext ctx;
  final Set<String> initial;

  @override
  State<_PickAssets> createState() => _PickAssetsState();
}

class _PickAssetsState extends State<_PickAssets> {
  late final Set<String> _sel = {...widget.initial};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = [
      for (final a in widget.assets)
        if (a.matches(_q, model: widget.ctx.models[a.modelId])) a,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: FilledButton(
                key: const Key('pickDone'),
                style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
                onPressed: () => Navigator.pop(context, _sel),
                child: Text(l.done),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: l.searchItems),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final a in list)
                    CheckboxListTile(
                      key: Key('pick-${a.internalCode}'),
                      value: _sel.contains(a.id),
                      onChanged: (v) => setState(() => v == true ? _sel.add(a.id) : _sel.remove(a.id)),
                      title: Text(widget.ctx.resolver.label(a)),
                      subtitle: Text(widget.ctx.where(a, inTransit: l.inTransit, withPerson: l.withPerson)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
