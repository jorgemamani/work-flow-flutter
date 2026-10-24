import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';
import 'item_lookup.dart';
import 'scan_page.dart';

/// Dónde queda el ítem al darlo de alta.
class _Holder {
  const _Holder(this.type, this.id, this.label, this.icon, {this.effectiveLocationId, this.effectiveProjectId, this.subtitle});

  final String type;
  final String id;
  final String label;
  final IconData icon;
  final String? subtitle;
  final String? effectiveLocationId;
  final String? effectiveProjectId;

  String get key => '$type:$id';
}

/// Alta de un ítem desde el celular, también sin señal (D-18, contrato §4).
/// Solo con `inventory.write`. Los consumibles (BULK) no se dan de alta acá:
/// son stock.
class NewItemPage extends StatefulWidget {
  const NewItemPage({super.key, this.initialCode, this.initialBarcode});

  final String? initialCode;
  final String? initialBarcode;

  @override
  State<NewItemPage> createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initialCode);
  late final _barcode = TextEditingController(text: widget.initialBarcode);
  final _serial = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _plate = TextEditingController();
  final _chassis = TextEditingController();
  final _engine = TextEditingController();
  final _year = TextEditingController();
  final _photos = <LocalPhoto>[];

  ItemContext? _ctx;
  AssetModel? _model;
  String? _conditionId;
  _Holder? _holder;
  String? _custodianId;
  bool _saving = false;
  bool _showErrors = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    ItemContext.load().then((ctx) {
      if (mounted) setState(() => _ctx = ctx);
    });
  }

  @override
  void dispose() {
    for (final c in [_code, _barcode, _serial, _description, _notes, _plate, _chassis, _engine, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Holder> _holders(BuildContext context, ItemContext ctx, String? projectId, String? employeeId) {
    final l = context.l10n;
    final locations = [
      for (final loc in ctx.locations.values)
        if (loc.isActive && (loc.projectId == projectId || loc.projectId == null))
          _Holder(HolderTypes.location, loc.id, loc.name, Icons.place_outlined,
              effectiveLocationId: loc.id,
              effectiveProjectId: loc.projectId,
              subtitle: loc.projectId == null ? '${l.locationType(loc.type)} · ${l.companyLocation}' : l.locationType(loc.type)),
    ]..sort((a, b) {
        // Primero las del proyecto, después las de la empresa.
        final pa = a.effectiveProjectId == null ? 1 : 0;
        final pb = b.effectiveProjectId == null ? 1 : 0;
        return pa != pb ? pa - pb : a.label.compareTo(b.label);
      });
    final carriers = [
      for (final x in ctx.assets.values)
        if (x.holderType != HolderTypes.inTransit &&
            ((ctx.models[x.modelId]?.isContainer ?? false) || (ctx.models[x.modelId]?.isVehicle ?? false)))
          _Holder(HolderTypes.asset, x.id, ctx.resolver.label(x),
              (ctx.models[x.modelId]?.isVehicle ?? false) ? Icons.local_shipping_outlined : Icons.all_inbox_outlined,
              effectiveLocationId: x.effectiveLocationId,
              effectiveProjectId: x.effectiveProjectId,
              subtitle: ctx.where(x, inTransit: l.inTransit, withPerson: l.withPerson)),
    ]..sort((a, b) => a.label.compareTo(b.label));
    return [
      ...locations,
      ...carriers,
      if (employeeId != null)
        _Holder(HolderTypes.employee, employeeId, l.toMyCharge, Icons.back_hand_outlined, effectiveProjectId: projectId),
    ];
  }

  Future<void> _pickModel(ItemContext ctx) async {
    final l = context.l10n;
    final models = [
      for (final m in ctx.models.values)
        if (!m.isBulk) m,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final picked = await showModalBottomSheet<AssetModel>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _ModelPicker(models: models, ctx: ctx, title: l.chooseModel),
    );
    if (picked != null) {
      setState(() {
        _model = picked;
        if (!picked.requiresCustody) _custodianId = null;
      });
    }
  }

  Future<void> _scanInto(TextEditingController controller) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanPage(captureCode: true)),
    );
    if (code != null) setState(() => controller.text = code);
  }

  Future<void> _pickHolder(List<_Holder> holders) async {
    final l = context.l10n;
    final picked = await showModalBottomSheet<_Holder>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.75,
          child: Column(
            children: [
              ListTile(title: Text(l.initialLocation, style: const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(
                child: ListView(
                  children: [
                    for (final h in holders)
                      ListTile(
                        key: Key('holder-${h.label}'),
                        leading: Icon(h.icon),
                        title: Text(h.label),
                        subtitle: h.subtitle == null ? null : Text(h.subtitle!),
                        trailing: h.key == _holder?.key ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(c, h),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _holder = picked);
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _showErrors = true;
      _codeError = null;
    });
    final model = _model;
    final holder = _holder;
    if (!_form.currentState!.validate() || model == null || holder == null) return;
    if (model.requiresPhoto && _photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.photoRequired)));
      return;
    }
    if (model.requiresCustody && _custodianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.custodianRequired)));
      return;
    }
    final code = _code.text.trim();
    // Validación local: la API respondería 409 (contrato §4).
    if (await sl<FieldRepository>().internalCodeInUse(code)) {
      setState(() => _codeError = l.codeAlreadyUsed(code));
      return;
    }
    setState(() => _saving = true);
    final id = await sl<FieldActions>().createAsset(
      AssetDraft(
        model: model,
        internalCode: code,
        holderType: holder.type,
        holderId: holder.id,
        effectiveLocationId: holder.effectiveLocationId,
        effectiveProjectId: holder.effectiveProjectId,
        manufacturerBarcode: _barcode.text,
        serialNumber: _serial.text,
        conditionId: _conditionId,
        description: _description.text,
        notes: _notes.text,
        licensePlate: _plate.text,
        chassisNumber: _chassis.text,
        engineNumber: _engine.text,
        year: int.tryParse(_year.text),
        custodianEmployeeId: _custodianId,
      ),
      photos: _photos,
    );
    if (!mounted) return;
    showSaved(context);
    context.pushReplacement(RouteNames.itemDetail(id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ctx = _ctx;
    if (ctx == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = context.watch<SessionCubit>().state;
    final profile = session.profile!;
    final holders = _holders(context, ctx, session.projectId, profile.employeeId);
    _holder ??= holders.isEmpty
        ? null
        : holders.firstWhere(
            (h) => h.type == HolderTypes.location && h.effectiveProjectId == session.projectId,
            orElse: () => holders.first,
          );
    final model = _model;
    final brand = model == null ? null : ctx.brands[model.brandId];
    final maxPhotos = profile.maxPhotosPerVerification;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.requiredField : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.newItem)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // Modelo
            Card(
              child: ListTile(
                key: const Key('pickModel'),
                leading: const Icon(Icons.category_outlined),
                title: Text(model?.name ?? l.chooseModel),
                subtitle: model == null
                    ? (_showErrors ? Text(l.requiredField, style: const TextStyle(color: AppColors.statusError)) : null)
                    : Text([if (brand != null) brand.name, model.category].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickModel(ctx),
              ),
            ),
            if (model != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.sm),
                child: Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.xs,
                  children: [
                    if (model.requiresSerialNumber) StatusChip(l.serialRequired, icon: Icons.numbers),
                    if (model.requiresPhoto) StatusChip(l.requiresPhoto, color: AppColors.statusWarning, icon: Icons.photo_camera),
                    if (model.requiresCustody) StatusChip(l.custodyRequired, icon: Icons.person_outline),
                    if (model.isVehicle) StatusChip(l.vehicle, icon: Icons.local_shipping_outlined),
                    if (model.isContainer) StatusChip(l.container, icon: Icons.all_inbox_outlined),
                  ],
                ),
              ),
            SectionTitle(l.codes),
            TextFormField(
              key: const Key('newItemCode'),
              controller: _code,
              validator: required,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) {
                if (_codeError != null) setState(() => _codeError = null);
              },
              decoration: InputDecoration(
                labelText: l.internalCode,
                errorText: _codeError,
                suffixIcon: IconButton(
                  tooltip: l.actionScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _scanInto(_code),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              key: const Key('newItemBarcode'),
              controller: _barcode,
              decoration: InputDecoration(
                labelText: l.barcodeOptional,
                suffixIcon: IconButton(
                  tooltip: l.actionScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _scanInto(_barcode),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              controller: _serial,
              validator: model?.requiresSerialNumber ?? false ? required : null,
              decoration: InputDecoration(
                labelText: model?.requiresSerialNumber ?? false ? l.serialNumber : l.serialNumberOptional,
              ),
            ),
            if (model?.isVehicle ?? false) ...[
              SectionTitle(l.vehicleData),
              TextFormField(
                controller: _plate,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l.licensePlate),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(controller: _chassis, decoration: InputDecoration(labelText: l.chassisNumber)),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(controller: _engine, decoration: InputDecoration(labelText: l.engineNumber)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                decoration: InputDecoration(labelText: l.year),
              ),
            ],
            SectionTitle(l.initialLocation),
            Card(
              child: ListTile(
                key: const Key('pickHolder'),
                leading: Icon(_holder?.icon ?? Icons.place_outlined),
                title: Text(_holder?.label ?? l.chooseLocation),
                subtitle: _holder?.subtitle == null ? null : Text(_holder!.subtitle!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickHolder(holders),
              ),
            ),
            if (model?.requiresCustody ?? false) ...[
              SectionTitle(l.custodian),
              DropdownButtonFormField<String>(
                initialValue: _custodianId,
                decoration: InputDecoration(labelText: l.custodian),
                validator: (v) => v == null ? l.requiredField : null,
                items: [
                  if (profile.employeeId != null)
                    DropdownMenuItem(value: profile.employeeId, child: Text('${profile.fullName} (${l.me})')),
                  for (final e in ctx.employees.values)
                    if (e.id != profile.employeeId) DropdownMenuItem(value: e.id, child: Text(e.fullName)),
                ],
                onChanged: (v) => setState(() => _custodianId = v),
              ),
            ],
            if (ctx.conditions.isNotEmpty) ...[
              SectionTitle(l.condition),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  for (final c in ctx.conditions)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _conditionId == c.id,
                      onSelected: (sel) => setState(() => _conditionId = sel ? c.id : null),
                    ),
                ],
              ),
            ],
            SectionTitle(l.photos),
            PhotoStrip(
              photos: _photos,
              max: maxPhotos,
              required: model?.requiresPhoto ?? false,
              showError: _showErrors,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: l.descriptionOptional),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.notesOptional),
            ),
            const LocalSaveHint(),
            FilledButton(
              key: const Key('saveNewItem'),
              onPressed: _saving ? null : _save,
              child: Text(l.createItem),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPicker extends StatefulWidget {
  const _ModelPicker({required this.models, required this.ctx, required this.title});

  final List<AssetModel> models;
  final ItemContext ctx;
  final String title;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _q.trim().toLowerCase();
    final list = [
      for (final m in widget.models)
        if (q.isEmpty ||
            m.name.toLowerCase().contains(q) ||
            (widget.ctx.brands[m.brandId]?.name.toLowerCase().contains(q) ?? false))
          m,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            ListTile(title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: l.searchModels),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.category_outlined, text: l.noModels)
                  : ListView(
                      children: [
                        for (final m in list)
                          ListTile(
                            key: Key('model-${m.name}'),
                            title: Text(m.name),
                            subtitle: Text([
                              if (widget.ctx.brands[m.brandId] != null) widget.ctx.brands[m.brandId]!.name,
                              m.category,
                            ].join(' · ')),
                            onTap: () => Navigator.pop(context, m),
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
