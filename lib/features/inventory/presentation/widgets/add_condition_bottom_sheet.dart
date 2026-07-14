import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/color_utils.dart';
import '../../../../shared/utils/bottom_sheet_utils.dart';
import '../../../../shared/widgets/app_button.dart';

typedef OnConditionCreated = Future<void> Function(String name, String color);

class AddConditionBottomSheet extends StatefulWidget {
  const AddConditionBottomSheet({super.key, required this.onConfirm});

  final OnConditionCreated onConfirm;

  @override
  State<AddConditionBottomSheet> createState() =>
      _AddConditionBottomSheetState();
}

class _AddConditionBottomSheetState extends State<AddConditionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hexCtrl = TextEditingController(text: '#4CAF50');
  Color _selectedColor = kConditionPresetColors.first;

  @override
  void initState() {
    super.initState();
    _hexCtrl.addListener(_onHexChanged);
  }

  void _onHexChanged() {
    final parsed = colorFromHex(_hexCtrl.text);
    if (parsed != null && parsed != _selectedColor) {
      setState(() => _selectedColor = parsed);
    }
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexCtrl.text = hexFromColor(color);
    });
  }

  @override
  void dispose() {
    _hexCtrl.removeListener(_onHexChanged);
    _nameCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.md + bottomInset,
      ),
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Nueva condición',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Bueno, Regular, En reparación...',
                filled: true,
                fillColor: AppColors.divider,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Color',
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
              children: kConditionPresetColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => _selectColor(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _hexCtrl,
              decoration: InputDecoration(
                labelText: 'Código hexadecimal',
                hintText: '#4CAF50',
                filled: true,
                fillColor: AppColors.divider,
                prefixIcon: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(7),
              ],
              validator: (v) {
                if (v == null || colorFromHex(v) == null) {
                  return 'Ingresá un color válido (#RRGGBB)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            AppButton(
              label: 'Agregar condición',
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                final hex = _hexCtrl.text.trim().toUpperCase();
                final normalized = hex.startsWith('#') ? hex : '#$hex';
                try {
                  await widget.onConfirm(_nameCtrl.text.trim(), normalized);
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {
                  // El error se muestra vía AlertManager en el caller.
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddConditionSheet({
  required BuildContext context,
  required OnConditionCreated onConfirm,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddConditionBottomSheet(onConfirm: onConfirm),
  );
}
