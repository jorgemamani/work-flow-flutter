import 'package:flutter/material.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/bottom_sheet_utils.dart';
import '../../../../shared/widgets/app_button.dart';

typedef OnCatalogItemCreated = Future<void> Function(String name);

/// Bottom sheet para agregar un nuevo ítem al catálogo (marca / modelo).
class AddCatalogBottomSheet extends StatefulWidget {
  const AddCatalogBottomSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.onConfirm,
  });

  final String title;
  final String hint;
  final OnCatalogItemCreated onConfirm;

  @override
  State<AddCatalogBottomSheet> createState() => _AddCatalogBottomSheetState();
}

class _AddCatalogBottomSheetState extends State<AddCatalogBottomSheet> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
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
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: true,
                fillColor: AppColors.divider,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo requerido'
                  : null,
            ),
            const SizedBox(height: AppSizes.md),
            AppButton(
              label: 'Agregar',
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                try {
                  await widget.onConfirm(_ctrl.text.trim());
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

Future<void> showAddCatalogSheet({
  required BuildContext context,
  required String title,
  required String hint,
  required OnCatalogItemCreated onConfirm,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddCatalogBottomSheet(
      title: title,
      hint: hint,
      onConfirm: onConfirm,
    ),
  );
}
