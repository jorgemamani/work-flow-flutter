import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/models.dart';
import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';
import '../items/item_lookup.dart';
import '../items/scan_page.dart';

/// Incidencia (REP-05): qué pasó, gravedad, ítem opcional y fotos.
class IncidentFormPage extends StatefulWidget {
  const IncidentFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> {
  static const _kinds = ['DAMAGE', 'LOSS', 'MISSING', 'CLAIM', 'OTHER'];
  static const _severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _photos = <LocalPhoto>[];
  String _kind = 'DAMAGE';
  String _severity = 'MEDIUM';
  Asset? _asset;
  ItemContext? _ctx;
  bool _saving = false;

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
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickAsset() async {
    final a = await Navigator.of(context).push<Asset>(
      MaterialPageRoute(builder: (_) => const ScanPage(pickOnly: true)),
    );
    if (a != null) setState(() => _asset = a);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await sl<FieldActions>().submitIncident(
      projectId: context.read<SessionCubit>().state.projectId!,
      kind: _kind,
      severity: _severity,
      title: _title.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(l.actionIncident)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          TextField(
            key: const Key('incidentTitle'),
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.incidentTitle),
          ),
          SectionTitle(l.kind),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final k in _kinds)
                ChoiceChip(label: Text(l.incidentKind(k)), selected: _kind == k, onSelected: (_) => setState(() => _kind = k)),
            ],
          ),
          SectionTitle(l.severityLabel),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final s in _severities)
                ChoiceChip(label: Text(l.severity(s)), selected: _severity == s, onSelected: (_) => setState(() => _severity = s)),
            ],
          ),
          SectionTitle(l.relatedItem),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(_asset == null || _ctx == null ? l.noItemSelected : _ctx!.resolver.label(_asset!)),
              trailing: _asset == null
                  ? const Icon(Icons.qr_code_scanner)
                  : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _asset = null)),
              onTap: _pickAsset,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.description, alignLabelWithHint: true),
          ),
          SectionTitle(l.photos),
          PhotoStrip(photos: _photos, max: maxPhotos, onChanged: () => setState(() {})),
          const SizedBox(height: AppSizes.md),
          const LocalSaveHint(),
          FilledButton(
            key: const Key('saveIncident'),
            onPressed: _title.text.trim().isEmpty || _saving ? null : _save,
            child: Text(l.send),
          ),
        ],
      ),
    );
  }
}
