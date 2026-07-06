import 'package:flutter/material.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';

/// Campo de selección con buscador interno y opción de añadir nuevo ítem.
/// T puede ser AssetBrand, AssetModelEntity u otro tipo con [id] y [name].
class CatalogSelectField<T> extends StatelessWidget {
  const CatalogSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedItem,
    required this.itemLabel,
    required this.onSelected,
    this.onAddNew,
    this.addNewLabel = 'Agregar nuevo',
    this.enabled = true,
    this.prefixIcon,
  });

  final String label;
  final String hint;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onSelected;
  final VoidCallback? onAddNew;
  final String addNewLabel;
  final bool enabled;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
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
          onTap: enabled ? () => _openSheet(context) : null,
          child: Container(
            height: AppSizes.inputHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled ? AppColors.border : AppColors.textDisabled,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              color: enabled ? null : AppColors.divider,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                Expanded(
                  child: Text(
                    selectedItem != null ? itemLabel(selectedItem as T) : hint,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedItem != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedItem != null)
                  GestureDetector(
                    onTap: enabled ? () => onSelected(null) : null,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatalogSheet<T>(
        label: label,
        items: items,
        selectedItem: selectedItem,
        itemLabel: itemLabel,
        onSelected: (item) {
          Navigator.pop(context);
          onSelected(item);
        },
        onAddNew: onAddNew != null
            ? () {
                Navigator.pop(context);
                onAddNew!();
              }
            : null,
        addNewLabel: addNewLabel,
      ),
    );
  }
}

class _CatalogSheet<T> extends StatefulWidget {
  const _CatalogSheet({
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.itemLabel,
    required this.onSelected,
    this.onAddNew,
    required this.addNewLabel,
  });

  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final VoidCallback? onAddNew;
  final String addNewLabel;

  @override
  State<_CatalogSheet<T>> createState() => _CatalogSheetState<T>();
}

class _CatalogSheetState<T> extends State<_CatalogSheet<T>> {
  late List<T> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((i) => widget.itemLabel(i).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.onAddNew != null)
                  TextButton.icon(
                    onPressed: widget.onAddNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(widget.addNewLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.divider,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final isSelected = widget.selectedItem == item;
                      return ListTile(
                        title: Text(widget.itemLabel(item)),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.primary)
                            : null,
                        selected: isSelected,
                        selectedTileColor:
                            AppColors.primary.withValues(alpha: 0.06),
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}
