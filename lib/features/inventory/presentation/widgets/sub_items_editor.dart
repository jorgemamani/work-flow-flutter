import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_sub_item.dart';

class SubItemsEditor extends StatelessWidget {
  const SubItemsEditor({
    super.key,
    required this.assetId,
    required this.subItems,
    required this.onChanged,
  });

  final String assetId;
  final List<AssetSubItem> subItems;
  final ValueChanged<List<AssetSubItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Contenido de la caja',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addItem(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar ítem'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: AppSizes.xs),
              ),
            ),
          ],
        ),
        if (subItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Center(
              child: Text(
                'Sin ítems aún. Toca "Agregar ítem" para comenzar.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subItems.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.xs),
            itemBuilder: (_, i) {
              final item = subItems[i];
              return _SubItemTile(
                item: item,
                index: i,
                onEdit: () => _editItem(context, i, item),
                onDelete: () {
                  final updated = List<AssetSubItem>.from(subItems)
                    ..removeAt(i);
                  onChanged(updated);
                },
              );
            },
          ),
      ],
    );
  }

  void _addItem(BuildContext context) {
    _openSubItemSheet(
      context: context,
      assetId: assetId,
      onSave: (item) {
        onChanged([...subItems, item]);
      },
    );
  }

  void _editItem(BuildContext context, int index, AssetSubItem item) {
    _openSubItemSheet(
      context: context,
      assetId: assetId,
      existing: item,
      onSave: (updated) {
        final list = List<AssetSubItem>.from(subItems);
        list[index] = updated;
        onChanged(list);
      },
    );
  }
}

// ── Sub-item tile ─────────────────────────────────────────────────────────────

class _SubItemTile extends StatelessWidget {
  const _SubItemTile({
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final AssetSubItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final condColor = _condColor(item.condition);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          item.description,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (item.brandName != null) item.brandName,
            if (item.serialNumber != null) 'S/N: ${item.serialNumber}',
            if (item.quantity > 1) 'x${item.quantity}',
          ].where((v) => v != null).join(' · '),
          style: const TextStyle(fontSize: 11),
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: condColor.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                item.condition.displayName,
                style: TextStyle(
                    fontSize: 10,
                    color: condColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 16),
              onPressed: onEdit,
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 16),
              onPressed: onDelete,
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Color _condColor(AssetCondition c) {
    switch (c) {
      case AssetCondition.good:
        return const Color(0xFF22C55E);
      case AssetCondition.regular:
        return const Color(0xFFF59E0B);
      case AssetCondition.bad:
        return const Color(0xFFEF4444);
    }
  }
}

// ── Sub-item sheet ────────────────────────────────────────────────────────────

void _openSubItemSheet({
  required BuildContext context,
  required String assetId,
  AssetSubItem? existing,
  required ValueChanged<AssetSubItem> onSave,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubItemSheet(
      assetId: assetId,
      existing: existing,
      onSave: onSave,
    ),
  );
}

class _SubItemSheet extends StatefulWidget {
  const _SubItemSheet({
    required this.assetId,
    this.existing,
    required this.onSave,
  });

  final String assetId;
  final AssetSubItem? existing;
  final ValueChanged<AssetSubItem> onSave;

  @override
  State<_SubItemSheet> createState() => _SubItemSheetState();
}

class _SubItemSheetState extends State<_SubItemSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _snCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _obsCtrl;
  late AssetCondition _condition;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _brandCtrl = TextEditingController(text: e?.brandName ?? '');
    _snCtrl = TextEditingController(text: e?.serialNumber ?? '');
    _colorCtrl = TextEditingController(text: e?.color ?? '');
    _qtyCtrl =
        TextEditingController(text: e?.quantity.toString() ?? '1');
    _obsCtrl = TextEditingController(text: e?.observations ?? '');
    _condition = e?.condition ?? AssetCondition.good;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _snCtrl.dispose();
    _colorCtrl.dispose();
    _qtyCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.md + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                widget.existing == null
                    ? 'Nuevo ítem'
                    : 'Editar ítem',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _descCtrl,
                label: 'Descripción *',
                hint: 'Ej: Destornillador Phillips',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _brandCtrl,
                      label: 'Marca',
                      hint: 'Ej: Stanley',
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  SizedBox(
                    width: 80,
                    child: AppTextField(
                      controller: _qtyCtrl,
                      label: 'Cant.',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
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
              const Text(
                'Estado',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                children: AssetCondition.values.map((c) {
                  final selected = _condition == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: ChoiceChip(
                      label: Text(c.displayName),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _condition = c),
                      selectedColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _obsCtrl,
                label: 'Observaciones',
                hint: 'Opcional',
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.md),
              AppButton(
                label: widget.existing == null ? 'Agregar ítem' : 'Guardar',
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) return;
    final item = AssetSubItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      assetId: widget.assetId,
      description: _descCtrl.text.trim(),
      brandName: _brandCtrl.text.trim().isEmpty
          ? null
          : _brandCtrl.text.trim(),
      serialNumber: _snCtrl.text.trim().isEmpty
          ? null
          : _snCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      condition: _condition,
      observations: _obsCtrl.text.trim().isEmpty
          ? null
          : _obsCtrl.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? 0,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }
}
