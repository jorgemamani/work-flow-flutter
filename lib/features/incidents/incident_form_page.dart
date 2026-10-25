import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/models.dart';
import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';
import '../items/item_lookup.dart';
import '../items/scan_page.dart';

/// Incidencia (REP-05): qué pasó, ítem opcional, el relato, gravedad y
/// fotos (obligatoria si hay un daño).
class IncidentFormPage extends StatefulWidget {
  const IncidentFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> {
  static const _kinds = ['MISSING', 'DAMAGE', 'LOSS', 'CLAIM', 'OTHER'];
  static const _severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  final _description = TextEditingController();
  final _photos = <LocalPhoto>[];
  String _kind = 'DAMAGE';
  String _severity = 'MEDIUM';
  Asset? _asset;
  ItemContext? _ctx;
  bool _saving = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    ItemContext.load().then((ctx) {
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        if (widget.assetId != null) _asset = ctx.assets[widget.assetId];
      });
    });
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickAsset() async {
    final a = await Navigator.of(context).push<Asset>(
      MaterialPageRoute(builder: (_) => const ScanPage(pickOnly: true)),
    );
    if (a != null) setState(() => _asset = a);
  }

  bool get _needsPhoto => _kind == 'DAMAGE' && _photos.isEmpty;

  /// El título sale de lo que se contó (o del tipo): en campo se escribe una
  /// sola vez.
  String _title(BuildContext context) {
    final first = _description.text.trim().split('\n').first;
    if (first.isNotEmpty) return first.length > 80 ? '${first.substring(0, 80)}…' : first;
    final kind = context.l10n.incidentKind(_kind);
    return _asset == null ? kind : '$kind · ${_asset!.internalCode}';
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_needsPhoto) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.damagedNeedsPhoto)));
      return;
    }
    setState(() => _saving = true);
    await sl<FieldActions>().submitIncident(
      projectId: context.read<SessionCubit>().state.projectId!,
      kind: _kind,
      severity: _severity,
      title: _title(context),
      description: _description.text.trim(),
      assetId: _asset?.id,
      photos: _photos,
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final maxPhotos = context.read<SessionCubit>().state.profile?.maxPhotosPerVerification ?? 5;
    final hints = {
      'MISSING': l.hintMissing,
      'DAMAGE': l.hintDamage,
      'LOSS': l.hintLoss,
      'CLAIM': l.hintClaim,
      'OTHER': l.hintOther,
    };
    final asset = _asset;
    return FieldScaffold(
      title: l.reportIncident,
      footer: FieldFooter(
        hint: l.seeAnswerInRecords,
        children: [
          AppButton(
            key: const Key('saveIncident'),
            label: l.notifyLogistics,
            isLoading: _saving,
            onPressed: _description.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
      children: [
        FieldLabel(
          l.whatHappenedTitle,
          child: ChoiceGrid<String>(
            semanticLabel: l.kind,
            height: AppSizes.rowHeight,
            selected: _kind,
            onChanged: (v) => setState(() => _kind = v ?? _kind),
            options: [for (final k in _kinds) ChoiceOption(k, l.incidentKind(k), hint: hints[k])],
          ),
        ),
        FieldLabel(
          l.itemLabel,
          note: l.optional,
          child: Material(
            color: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: _pickAsset,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                  child: Row(
                    children: [
                      if (asset != null) ...[Chapa(asset.internalCode, fontSize: 13), const SizedBox(width: 12)],
                      Expanded(
                        child: Text(
                          asset == null || _ctx == null ? l.noItemSelected : _ctx!.modelName(asset),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: asset == null ? FontWeight.w400 : FontWeight.w600,
                            color: asset == null ? AppColors.textSecondary : AppColors.ink,
                          ),
                        ),
                      ),
                      if (asset != null)
                        IconButton(
                          tooltip: l.discard,
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _asset = null),
                        ),
                      TextButton(
                        style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 15, decoration: TextDecoration.underline)),
                        onPressed: _pickAsset,
                        child: Text(asset == null ? l.choose : l.change),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        FieldLabel(
          l.tellBriefly,
          child: TextField(
            key: const Key('incidentTitle'),
            controller: _description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17, height: 1.45),
            onChanged: (_) => setState(() {}),
          ),
        ),
        FieldLabel(
          l.severityLabel,
          child: ChoiceGrid<String>(
            semanticLabel: l.severityLabel,
            columns: 4,
            height: 48,
            selected: _severity,
            onChanged: (v) => setState(() => _severity = v ?? _severity),
            options: [for (final s in _severities) ChoiceOption(s, l.severity(s))],
          ),
        ),
        FieldLabel(
          l.photos,
          note: _kind == 'DAMAGE' ? l.photoRequiredIfDamage : l.photosOptional,
          child: PhotoStrip(
            photos: _photos,
            max: maxPhotos,
            required: _kind == 'DAMAGE',
            showError: _showErrors,
            onChanged: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}
