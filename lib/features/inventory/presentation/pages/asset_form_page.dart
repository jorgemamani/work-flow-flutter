import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/utils/color_utils.dart';
import '../../../../shared/utils/keyboard_utils.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';
import '../bloc/asset_form_bloc.dart';
import '../bloc/asset_form_event.dart';
import '../bloc/asset_form_state.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../utils/asset_form_catalog_utils.dart';
import '../widgets/add_catalog_bottom_sheet.dart';
import '../widgets/add_condition_bottom_sheet.dart';
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
  final _formKey = GlobalKey<FormState>();

  // Controllers – campos comunes
  late final TextEditingController _descCtrl;
  late final TextEditingController _snCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _internalCodeCtrl;

  // Controllers – vehículo
  late final TextEditingController _plateCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _engineCtrl;
  late final TextEditingController _chassisCtrl;
  late final TextEditingController _mileageCtrl;
  DateTime? _vtvExpiry;
  DateTime? _insuranceExpiry;

  // State local (el tipo vive en AssetFormBloc.selectedType — única fuente de verdad)
  late List<AssetSubItem> _subItems;
  final String _tempAssetId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _subItems = List.from(a?.subItems ?? []);

    _descCtrl = TextEditingController(text: a?.description ?? '');
    _snCtrl = TextEditingController(text: a?.serialNumber ?? '');
    _colorCtrl = TextEditingController(text: a?.color ?? '');
    _qtyCtrl = TextEditingController(text: a?.quantity.toString() ?? '1');
    _obsCtrl = TextEditingController(text: a?.observations ?? '');
    _internalCodeCtrl = TextEditingController(text: a?.internalCode ?? '');

    // Vehicle: patente visible; internalCode se deriva de la patente al guardar.
    _plateCtrl = TextEditingController(
      text: a?.licensePlate ??
          (a?.type == AssetType.vehicle ? a?.internalCode : null) ??
          '',
    );
    _yearCtrl = TextEditingController(
        text: a?.year != null ? a!.year.toString() : '');
    _engineCtrl = TextEditingController(text: a?.engineNumber ?? '');
    _chassisCtrl = TextEditingController(text: a?.chassisNumber ?? '');
    _mileageCtrl = TextEditingController(
        text: a?.mileage != null ? a!.mileage.toString() : '');
    _vtvExpiry = a?.vtvExpiry;
    _insuranceExpiry = a?.insuranceExpiry;

    context.read<AssetFormBloc>().add(AssetFormInitialized(asset: a));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _snCtrl.dispose();
    _colorCtrl.dispose();
    _qtyCtrl.dispose();
    _obsCtrl.dispose();
    _internalCodeCtrl.dispose();
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
      listenWhen: (p, c) =>
          c.status != p.status ||
          (c.errorMessage != null && c.errorMessage != p.errorMessage),
      listener: (context, state) {
        if (state.status == AssetFormStatus.success) {
          // InventoryBloc es singleton: este add() llega a la instancia
          // que usa InventoryPage y refresca la lista automáticamente.
          context.read<InventoryBloc>().add(const InventoryLoadRequested());
          Navigator.pop(context);
          AlertManager.showSnackBarSuccess(
            message: widget.asset == null
                ? 'Activo cargado correctamente'
                : 'Activo actualizado',
          );
        }
        if (state.status == AssetFormStatus.failure) {
          AlertManager.showSnackBarError(
            message: state.errorMessage ?? 'Error al guardar',
          );
        } else if (state.errorMessage != null &&
            state.status != AssetFormStatus.loading) {
          AlertManager.showSnackBarError(message: state.errorMessage!);
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
          child: BlocBuilder<AssetFormBloc, AssetFormState>(
            builder: (context, formState) {
              final type = formState.selectedType;
              return SingleChildScrollView(
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
                  selected: type,
                  onChanged: (t) {
                    hideKeyboard(context);
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
                if (type == AssetType.vehicle) ...[
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

                // Código interno (no vehículo — en vehículo se usa la patente)
                if (type != AssetType.vehicle) ...[
                  AppTextField(
                    controller: _internalCodeCtrl,
                    label: 'Código interno *',
                    hint: 'Ej: TOOL-042, EPP-015...',
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'El código interno es requerido'
                            : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                ],

                AppTextField(
                  controller: _descCtrl,
                  label: type == AssetType.vehicle
                      ? 'Descripción del vehículo *'
                      : 'Descripción *',
                  hint: _descHintFor(type),
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
                          isLoading: state.isLoadingCatalogs,
                          resolveItems: () =>
                              context.read<AssetFormBloc>().state.brands,
                          resolveSelectedItem: () =>
                              context.read<AssetFormBloc>().state.selectedBrand,
                          onSelected: (b) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormBrandSelected(b)),
                          prefixIcon: Icons.business_rounded,
                          onAddNew: () => showAddCatalogSheet(
                            context: context,
                            title: 'Nueva marca',
                            hint: 'Ej: Trimble, Stanley, Toyota...',
                            onConfirm: (name) => dispatchAssetFormCatalogEvent(
                              context,
                              event: AssetFormBrandCreated(name),
                              wasUpdated: (b, a) =>
                                  a.brands.length > b.brands.length,
                            ),
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
                          resolveItems: () =>
                              context.read<AssetFormBloc>().state.models,
                          resolveSelectedItem: () =>
                              context.read<AssetFormBloc>().state.selectedModel,
                          onSelected: (m) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormModelSelected(m)),
                          enabled: state.selectedBrand != null &&
                              !state.isLoadingModels,
                          isLoading: state.isLoadingModels,
                          prefixIcon: Icons.category_rounded,
                          onAddNew: state.selectedBrand != null
                              ? () => showAddCatalogSheet(
                                    context: context,
                                    title: 'Nuevo modelo',
                                    hint: 'Ej: SP 60 RTK, F-150...',
                                    onConfirm: (name) =>
                                        dispatchAssetFormCatalogEvent(
                                      context,
                                      event: AssetFormModelCreated(
                                        brandId: state.selectedBrand!.id,
                                        name: name,
                                      ),
                                      wasUpdated: (b, a) =>
                                          a.models.length > b.models.length,
                                    ),
                                  )
                              : null,
                          addNewLabel: 'Nuevo modelo',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSizes.md),

                // N° serie y color (no vehículo)
                if (type != AssetType.vehicle) ...[
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
                ],

                // ── Campos exclusivos de vehículo ────────────────────
                if (type == AssetType.vehicle) ...[
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
                        child: _DateField(
                          label: 'Vence VTV',
                          value: _vtvExpiry,
                          onChanged: (d) =>
                              setState(() => _vtvExpiry = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  _DateField(
                    label: 'Vence seguro',
                    value: _insuranceExpiry,
                    onChanged: (d) =>
                        setState(() => _insuranceExpiry = d),
                  ),
                ],

                // ── Sección: Ubicación ───────────────────────────────
                const SizedBox(height: AppSizes.lg),
                const _SectionHeader(
                  icon: Icons.location_on_rounded,
                  title: 'Ubicación / Asignación',
                ),
                const SizedBox(height: AppSizes.md),
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        CatalogSelectField<dynamic>(
                          label: 'Proyecto / Obra',
                          hint: 'Seleccionar proyecto',
                          items: state.projects,
                          selectedItem: state.selectedProject,
                          itemLabel: (p) => p.name as String,
                          isLoading: state.isLoadingCatalogs,
                          resolveItems: () =>
                              context.read<AssetFormBloc>().state.projects,
                          resolveSelectedItem: () =>
                              context.read<AssetFormBloc>().state.selectedProject,
                          onSelected: (p) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormProjectSelected(p)),
                          prefixIcon: Icons.construction_rounded,
                          onAddNew: () => showAddCatalogSheet(
                            context: context,
                            title: 'Nuevo proyecto',
                            hint: 'Ej: Mina Veladero 2025, Oficina Central...',
                            onConfirm: (name) => dispatchAssetFormCatalogEvent(
                              context,
                              event: AssetFormProjectCreated(name),
                              wasUpdated: (b, a) =>
                                  a.projects.length > b.projects.length,
                            ),
                          ),
                          addNewLabel: 'Nuevo proyecto',
                        ),
                        const SizedBox(height: AppSizes.md),
                        CatalogSelectField<dynamic>(
                          label: 'Almacén / Sub-ubicación',
                          hint: 'Seleccionar almacén',
                          items: state.warehouses,
                          selectedItem: state.selectedWarehouse,
                          itemLabel: (w) => w.name as String,
                          isLoading: state.isLoadingCatalogs,
                          resolveItems: () =>
                              context.read<AssetFormBloc>().state.warehouses,
                          resolveSelectedItem: () => context
                              .read<AssetFormBloc>()
                              .state
                              .selectedWarehouse,
                          onSelected: (w) => context
                              .read<AssetFormBloc>()
                              .add(AssetFormWarehouseSelected(w)),
                          prefixIcon: Icons.warehouse_rounded,
                          onAddNew: () => showAddCatalogSheet(
                            context: context,
                            title: 'Nuevo almacén',
                            hint: 'Ej: Depósito Norte, Almacén Central...',
                            onConfirm: (name) => dispatchAssetFormCatalogEvent(
                              context,
                              event: AssetFormWarehouseCreated(name),
                              wasUpdated: (b, a) =>
                                  a.warehouses.length > b.warehouses.length,
                            ),
                          ),
                          addNewLabel: 'Nuevo almacén',
                        ),
                      ],
                    );
                  },
                ),

                // ── Estado ───────────────────────────────────────────
                const SizedBox(height: AppSizes.lg),
                const _SectionHeader(
                  icon: Icons.health_and_safety_rounded,
                  title: 'Estado / Condición',
                ),
                const SizedBox(height: AppSizes.md),
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return CatalogSelectField<ConditionEntity>(
                      label: 'Condición',
                      hint: 'Seleccionar condición',
                      items: state.conditions,
                      selectedItem: state.selectedCondition,
                      itemLabel: (c) => c.name,
                      isLoading: state.isLoadingCatalogs,
                      resolveItems: () =>
                          context.read<AssetFormBloc>().state.conditions,
                      resolveSelectedItem: () =>
                          context.read<AssetFormBloc>().state.selectedCondition,
                      prefixIcon: Icons.health_and_safety_rounded,
                      leadingBuilder: (c) => Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorFromHex(c.color) ?? AppColors.border,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      onSelected: (c) => context
                          .read<AssetFormBloc>()
                          .add(AssetFormConditionSelected(c)),
                      onAddNew: () => showAddConditionSheet(
                        context: context,
                        onConfirm: (name, color) =>
                            dispatchAssetFormCatalogEvent(
                          context,
                          event: AssetFormConditionCreated(
                            name: name,
                            color: color,
                          ),
                          wasUpdated: (b, a) =>
                              a.conditions.length > b.conditions.length,
                        ),
                      ),
                      addNewLabel: 'Nueva condición',
                    );
                  },
                ),

                // ── Sub-ítems (toolBox) ──────────────────────────────
                if (type == AssetType.toolBox) ...[
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
                      photos: state.photos,
                      onAdd: (path, contentType) => context
                          .read<AssetFormBloc>()
                          .add(AssetFormPhotoAdded(
                            path: path,
                            contentType: contentType,
                          )),
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
                  hint: 'Estado, historial, notas relevantes...',
                  maxLines: 3,
                ),

                // ── Submit ───────────────────────────────────────────
                const SizedBox(height: AppSizes.xl),
                BlocBuilder<AssetFormBloc, AssetFormState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        AppButton(
                          label: widget.asset == null
                              ? 'Guardar activo'
                              : 'Actualizar activo',
                          isLoading:
                              state.status == AssetFormStatus.loading,
                          onPressed: () => _submit(context, state),
                        ),
                        if (state.isUploadingPhotos) ...[
                          const SizedBox(height: AppSizes.sm),
                          const Text(
                            'Subiendo fotos, no cierres la pantalla...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
            },
          ),
        ),
      ),
    );
  }

  static String _descHintFor(AssetType type) {
    switch (type) {
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

  /// En vehículos la API exige [internalCode] y se envía igual que la patente.
  String _resolvedInternalCode(AssetType type) {
    if (type == AssetType.vehicle) {
      return _plateCtrl.text.trim().toUpperCase();
    }
    return _internalCodeCtrl.text.trim();
  }

  void _submit(BuildContext context, AssetFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final type = state.selectedType;
    final model = state.selectedModel;

    if (model == null ||
        !state.models.any((m) => m.id == model.id)) {
      AlertManager.showSnackBarError(
        message:
            'Seleccioná un modelo de tipo ${type.label}. '
            'Si cambiaste el tipo de activo, elegí el modelo nuevamente.',
      );
      return;
    }

    final condition = state.selectedCondition;
    if (condition == null) {
      AlertManager.showSnackBarError(
        message: 'Seleccioná una condición para continuar',
      );
      return;
    }

    final assetId = widget.asset?.id ?? '';
    final brand = state.selectedBrand;

    final asset = Asset(
      id: assetId,
      type: type,
      internalCode: _resolvedInternalCode(type),
      description: _descCtrl.text.trim(),
      brandId: brand?.id,
      brandName: brand?.name,
      modelId: model.id,
      modelName: model.name,
      serialNumber:
          _snCtrl.text.trim().isEmpty ? null : _snCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      currentProjectId: state.selectedProject?.id,
      currentProjectName: state.selectedProject?.name,
      currentWarehouseId: state.selectedWarehouse?.id,
      currentWarehouseName: state.selectedWarehouse?.name,
      location:
          state.selectedWarehouse?.name ?? state.selectedProject?.name,
      conditionId: condition.id,
      conditionName: condition.name,
      conditionColor: condition.color,
      observations:
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      photoPaths: state.photoPaths,
      subItems: _subItems,
      // Vehicle
      licensePlate: type == AssetType.vehicle
          ? (_plateCtrl.text.trim().isEmpty
              ? null
              : _plateCtrl.text.trim().toUpperCase())
          : null,
      year: type == AssetType.vehicle
          ? int.tryParse(_yearCtrl.text)
          : null,
      engineNumber: type == AssetType.vehicle
          ? (_engineCtrl.text.trim().isEmpty
              ? null
              : _engineCtrl.text.trim())
          : null,
      chassisNumber: type == AssetType.vehicle
          ? (_chassisCtrl.text.trim().isEmpty
              ? null
              : _chassisCtrl.text.trim())
          : null,
      mileage: type == AssetType.vehicle
          ? int.tryParse(_mileageCtrl.text)
          : null,
      vtvExpiry: type == AssetType.vehicle ? _vtvExpiry : null,
      insuranceExpiry:
          type == AssetType.vehicle ? _insuranceExpiry : null,
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
              onTap: () {
                hideKeyboard(context);
                onChanged(t);
              },
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
                        color: isSelected ? color : AppColors.textSecondary,
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
          child: Divider(color: AppColors.border, height: 1),
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.md),
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
