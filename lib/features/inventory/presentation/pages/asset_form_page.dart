import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';
import '../bloc/asset_form_bloc.dart';
import '../bloc/asset_form_event.dart';
import '../bloc/asset_form_state.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../widgets/add_catalog_bottom_sheet.dart';
import '../widgets/asset_type_theme.dart';
import '../widgets/catalog_select_field.dart';
import '../widgets/photo_picker_widget.dart';
import '../widgets/sub_items_editor.dart';

class AssetFormPage extends StatefulWidget {
  const AssetFormPage({super.key, this.asset});

  /// Pasado al editar; null al crear.
  final Asset? asset;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers – campos comunes
  late final TextEditingController _descCtrl;
  late final TextEditingController _snCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _obsCtrl;

  // Controllers – vehículo
  late final TextEditingController _plateCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _engineCtrl;
  late final TextEditingController _chassisCtrl;
  late final TextEditingController _mileageCtrl;
  DateTime? _vtvExpiry;
  DateTime? _insuranceExpiry;

  // State local
  late AssetType _type;
  late AssetCondition _condition;
  late List<AssetSubItem> _subItems;
  final String _tempAssetId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _type = a?.type ?? AssetType.tool;
    _condition = a?.condition ?? AssetCondition.good;
    _subItems = List.from(a?.subItems ?? []);

    _descCtrl = TextEditingController(text: a?.description ?? '');
    _snCtrl = TextEditingController(text: a?.serialNumber ?? '');
    _colorCtrl = TextEditingController(text: a?.color ?? '');
    _qtyCtrl = TextEditingController(text: a?.quantity.toString() ?? '1');
    _locationCtrl = TextEditingController(text: a?.location ?? '');
    _obsCtrl = TextEditingController(text: a?.observations ?? '');

    // Vehicle
    _plateCtrl = TextEditingController(text: a?.licensePlate ?? '');
    _yearCtrl = TextEditingController(
        text: a?.year != null ? a!.year.toString() : '');
    _engineCtrl = TextEditingController(text: a?.engineNumber ?? '');
    _chassisCtrl = TextEditingController(text: a?.chassisNumber ?? '');
    _mileageCtrl = TextEditingController(
        text: a?.mileage != null ? a!.mileage.toString() : '');
    _vtvExpiry = a?.vtvExpiry;
    _insuranceExpiry = a?.insuranceExpiry;

    // Init BLoC
    context.read<AssetFormBloc>().add(AssetFormInitialized(asset: a));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _snCtrl.dispose();
    _colorCtrl.dispose();
    _qtyCtrl.dispose();
    _locationCtrl.dispose();
    _obsCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _engineCtrl.dispose();
    _chassisCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssetFormBloc, AssetFormState>(
      listenWhen: (p, c) => c.status != p.status,
      listener: (context, state) {
        if (state.status == AssetFormStatus.success) {
          context.read<InventoryBloc>().add(const InventoryLoadRequested());
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.asset == null
                    ? 'Activo cargado correctamente'
                    : 'Activo actualizado',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state.status == AssetFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error al guardar'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.asset == null ? 'Cargar activo' : 'Editar activo',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeSelector(
                  selected: _type,
                  onChanged: (t) {
                    setState(() => _type = t);
                    context
                        .read<AssetFormBloc>()
                        .add(AssetFormTypeChanged(t));
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // ── Sección: Identificación ──────────────────────────
                const _SectionHeader(
                  icon: Icons.label_rounded,
                  title: 'Identificación',
                ),
                const SizedBox(height: AppSizes.md),

                // Patente (solo vehículo)
                if (_type == AssetType.vehicle) ...[
                  AppTextField(
                    controller: _plateCtrl,
                    label: 'Patente / Dominio *',
                    hint: 'Ej: AF903JN',
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'La patente es requerida'
                            : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                ],

                AppTextField(
                  controller: _descCtrl,
                  label: _type == AssetType.vehicle
                      ? 'Descripción del vehículo *'
                      : 'Descripción *',
                  hint: _descHint,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'La descripción es requerida'
                          : null,
                ),
                const SizedBox(height: AppSizes.md),

                // Marca y modelo
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        CatalogSelectField<dynamic>(
                          label: 'Marca',
                          hint: 'Seleccionar marca',
                          items: state.brands,
                          selectedItem: state.selectedBrand,
                          itemLabel: (b) => b.name as String,
                          onSelected: (b) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormBrandSelected(b)),
                          prefixIcon: Icons.business_rounded,
                          onAddNew: () => showAddCatalogSheet(
                            context: context,
                            title: 'Nueva marca',
                            hint: 'Ej: Trimble, Stanley, Toyota...',
                            onConfirm: (name) => context
                                .read<AssetFormBloc>()
                                .add(AssetFormBrandCreated(name)),
                          ),
                          addNewLabel: 'Nueva marca',
                        ),
                        const SizedBox(height: AppSizes.md),
                        CatalogSelectField<dynamic>(
                          label: 'Modelo',
                          hint: state.selectedBrand == null
                              ? 'Seleccionar primero una marca'
                              : 'Seleccionar modelo',
                          items: state.models,
                          selectedItem: state.selectedModel,
                          itemLabel: (m) => m.name as String,
                          onSelected: (m) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormModelSelected(m)),
                          enabled: state.selectedBrand != null,
                          prefixIcon: Icons.category_rounded,
                          onAddNew: state.selectedBrand != null
                              ? () => showAddCatalogSheet(
                                    context: context,
                                    title: 'Nuevo modelo',
                                    hint: 'Ej: SP 60 RTK, F-150...',
                                    onConfirm: (name) => context
                                        .read<AssetFormBloc>()
                                        .add(AssetFormModelCreated(
                                          brandId: state.selectedBrand!.id,
                                          name: name,
                                        )),
                                  )
                              : null,
                          addNewLabel: 'Nuevo modelo',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSizes.md),

                // N° serie y color
                if (_type != AssetType.vehicle) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _snCtrl,
                          label: 'N° de serie',
                          hint: 'Opcional',
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _colorCtrl,
                          label: 'Color',
                          hint: 'Opcional',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: AppTextField(
                          controller: _qtyCtrl,
                          label: 'Cantidad',
                          hint: '1',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _locationCtrl,
                          label: 'Ubicación',
                          hint: 'Ej: OF. CENTRAL, CAMPO...',
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Campos exclusivos de vehículo ────────────────────
                if (_type == AssetType.vehicle) ...[
                  const SizedBox(height: AppSizes.md),
                  const _SectionHeader(
                    icon: Icons.directions_car_rounded,
                    title: 'Datos del vehículo',
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _yearCtrl,
                          label: 'Año',
                          hint: 'Ej: 2022',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _colorCtrl,
                          label: 'Color',
                          hint: 'Ej: Blanco',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    controller: _engineCtrl,
                    label: 'N° de motor',
                    hint: 'Opcional',
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    controller: _chassisCtrl,
                    label: 'N° de chasis (VIN)',
                    hint: 'Opcional',
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _mileageCtrl,
                          label: 'Km actuales',
                          hint: 'Ej: 45000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _locationCtrl,
                          label: 'Ubicación / Asignación',
                          hint: 'Ej: Campamento',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Vence VTV',
                          value: _vtvExpiry,
                          onChanged: (d) =>
                              setState(() => _vtvExpiry = d),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _DateField(
                          label: 'Vence seguro',
                          value: _insuranceExpiry,
                          onChanged: (d) =>
                              setState(() => _insuranceExpiry = d),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Estado ───────────────────────────────────────────
                const SizedBox(height: AppSizes.lg),
                const _SectionHeader(
                  icon: Icons.health_and_safety_rounded,
                  title: 'Estado / Condición',
                ),
                const SizedBox(height: AppSizes.md),
                _ConditionSelector(
                  selected: _condition,
                  onChanged: (c) => setState(() => _condition = c),
                ),

                // ── Sub-ítems (toolBox) ──────────────────────────────
                if (_type == AssetType.toolBox) ...[
                  const SizedBox(height: AppSizes.lg),
                  const _SectionHeader(
                    icon: Icons.list_alt_rounded,
                    title: 'Contenido de la caja',
                  ),
                  const SizedBox(height: AppSizes.md),
                  SubItemsEditor(
                    assetId: widget.asset?.id ?? _tempAssetId,
                    subItems: _subItems,
                    onChanged: (items) =>
                        setState(() => _subItems = items),
                  ),
                ],

                // ── Fotos ────────────────────────────────────────────
                const SizedBox(height: AppSizes.lg),
                const _SectionHeader(
                  icon: Icons.photo_library_rounded,
                  title: 'Fotos',
                ),
                const SizedBox(height: AppSizes.md),
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return PhotoPickerWidget(
                      photos: state.photoPaths,
                      onAdd: (path) => context
                          .read<AssetFormBloc>()
                          .add(AssetFormPhotoAdded(path)),
                      onRemove: (i) => context
                          .read<AssetFormBloc>()
                          .add(AssetFormPhotoRemoved(i)),
                    );
                  },
                ),

                // ── Observaciones ────────────────────────────────────
                const SizedBox(height: AppSizes.lg),
                const _SectionHeader(
                  icon: Icons.notes_rounded,
                  title: 'Observaciones',
                ),
                const SizedBox(height: AppSizes.md),
                AppTextField(
                  controller: _obsCtrl,
                  label: '',
                  hint:
                      'Estado, historial, notas relevantes...',
                  maxLines: 3,
                ),

                // ── Submit ───────────────────────────────────────────
                const SizedBox(height: AppSizes.xl),
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return AppButton(
                      label: widget.asset == null
                          ? 'Guardar activo'
                          : 'Actualizar activo',
                      isLoading: state.status == AssetFormStatus.loading,
                      onPressed: () => _submit(context, state),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _descHint {
    switch (_type) {
      case AssetType.vehicle:
        return 'Ej: Camioneta Toyota Hilux doble cabina';
      case AssetType.tool:
        return 'Ej: Estación total Trimble S5';
      case AssetType.toolBox:
        return 'Ej: Caja de herramientas azul ROBUS';
      case AssetType.epp:
        return 'Ej: Casco de seguridad amarillo';
      case AssetType.cable:
        return 'Ej: Cable USB-C de carga controladora';
      case AssetType.consumable:
        return 'Ej: Pilas AAA para distanciómetro';
    }
  }

  void _submit(BuildContext context, AssetFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final assetId = widget.asset?.id ?? '';
    final brand = state.selectedBrand;
    final model = state.selectedModel;

    final asset = Asset(
      id: assetId,
      type: _type,
      description: _descCtrl.text.trim(),
      brandId: brand?.id,
      brandName: brand?.name,
      modelId: model?.id,
      modelName: model?.name,
      serialNumber:
          _snCtrl.text.trim().isEmpty ? null : _snCtrl.text.trim(),
      color:
          _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      condition: _condition,
      observations: _obsCtrl.text.trim().isEmpty
          ? null
          : _obsCtrl.text.trim(),
      photoPaths: state.photoPaths,
      subItems: _subItems,
      // Vehicle
      licensePlate: _type == AssetType.vehicle
          ? (_plateCtrl.text.trim().isEmpty
              ? null
              : _plateCtrl.text.trim().toUpperCase())
          : null,
      year: _type == AssetType.vehicle
          ? int.tryParse(_yearCtrl.text)
          : null,
      engineNumber: _type == AssetType.vehicle
          ? (_engineCtrl.text.trim().isEmpty
              ? null
              : _engineCtrl.text.trim())
          : null,
      chassisNumber: _type == AssetType.vehicle
          ? (_chassisCtrl.text.trim().isEmpty
              ? null
              : _chassisCtrl.text.trim())
          : null,
      mileage: _type == AssetType.vehicle
          ? int.tryParse(_mileageCtrl.text)
          : null,
      vtvExpiry:
          _type == AssetType.vehicle ? _vtvExpiry : null,
      insuranceExpiry:
          _type == AssetType.vehicle ? _insuranceExpiry : null,
      createdAt: widget.asset?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<AssetFormBloc>().add(AssetFormSubmitted(asset));
  }
}

// ── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final AssetType selected;
  final ValueChanged<AssetType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de activo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: AssetType.values.map((t) {
            final isSelected = t == selected;
            final color = AssetTypeTheme.colorFor(t);
            return GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.divider,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AssetTypeTheme.iconFor(t),
                      size: 16,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Condition selector ────────────────────────────────────────────────────────

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.selected, required this.onChanged});

  final AssetCondition selected;
  final ValueChanged<AssetCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AssetCondition.values.map((c) {
        final isSelected = c == selected;
        final color = AssetTypeTheme.conditionColor(c);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: AppSizes.sm),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : AppColors.divider,
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _condIcon(c),
                    size: 22,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _condIcon(AssetCondition c) {
    switch (c) {
      case AssetCondition.good:
        return Icons.check_circle_rounded;
      case AssetCondition.regular:
        return Icons.warning_amber_rounded;
      case AssetCondition.bad:
        return Icons.cancel_rounded;
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSizes.xs),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        const Expanded(
          child: Divider(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/'
            '${value!.year}'
        : 'Seleccionar fecha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            onChanged(picked);
          },
          child: Container(
            height: AppSizes.inputHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
