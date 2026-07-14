import 'package:flutter/material.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/bottom_sheet_utils.dart';
import '../../../../shared/utils/keyboard_utils.dart';

/// Campo de selección con buscador interno y opción de añadir nuevo ítem.
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
    this.isLoading = false,
    this.prefixIcon,
    this.leadingBuilder,
    this.resolveItems,
    this.resolveSelectedItem,
  });

  final String label;
  final String hint;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onSelected;
  final Future<void> Function()? onAddNew;
  final String addNewLabel;
  final bool enabled;
  final bool isLoading;
  final IconData? prefixIcon;

  /// Widget opcional a la izquierda del label en cada ítem del sheet.
  final Widget? Function(T item)? leadingBuilder;

  /// Proveedor en vivo para refrescar la lista del sheet tras crear un ítem.
  final List<T> Function()? resolveItems;

  /// Proveedor en vivo para marcar el ítem seleccionado tras crear uno nuevo.
  final T? Function()? resolveSelectedItem;

  @override
  Widget build(BuildContext context) {
    final displayHint = isLoading ? 'Cargando...' : hint;

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
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled && !isLoading
              ? (_) => hideKeyboard(context)
              : null,
          onTap: enabled && !isLoading ? () => _openSheet(context) : null,
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
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                if (!isLoading &&
                    selectedItem != null &&
                    leadingBuilder != null) ...[
                  leadingBuilder!(selectedItem as T)!,
                  const SizedBox(width: AppSizes.sm),
                ],
                Expanded(
                  child: Text(
                    selectedItem != null
                        ? itemLabel(selectedItem as T)
                        : displayHint,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedItem != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedItem != null && !isLoading)
                  GestureDetector(
                    onTap: enabled ? () => onSelected(null) : null,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  )
                else if (!isLoading)
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
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatalogSheet<T>(
        label: label,
        items: items,
        selectedItem: selectedItem,
        itemLabel: itemLabel,
        leadingBuilder: leadingBuilder,
        isLoading: isLoading,
        resolveItems: resolveItems,
        resolveSelectedItem: resolveSelectedItem,
        onSelected: (item) {
          Navigator.pop(context);
          onSelected(item);
        },
        onAddNew: onAddNew,
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
    this.leadingBuilder,
    this.isLoading = false,
    this.resolveItems,
    this.resolveSelectedItem,
  });

  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final Future<void> Function()? onAddNew;
  final String addNewLabel;
  final Widget? Function(T item)? leadingBuilder;
  final bool isLoading;
  final List<T> Function()? resolveItems;
  final T? Function()? resolveSelectedItem;

  @override
  State<_CatalogSheet<T>> createState() => _CatalogSheetState<T>();
}

class _CatalogSheetState<T> extends State<_CatalogSheet<T>> {
  late List<T> _items;
  late List<T> _filtered;
  final _searchCtrl = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _items = _resolveItems();
    _filtered = _items;
    _searchCtrl.addListener(_onSearch);
  }

  List<T> _resolveItems() => widget.resolveItems?.call() ?? widget.items;

  T? _resolveSelectedItem() =>
      widget.resolveSelectedItem?.call() ?? widget.selectedItem;

  void _refreshItems() {
    setState(() {
      _items = _resolveItems();
      _onSearch();
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _items
          : _items
              .where((i) => widget.itemLabel(i).toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _handleAddNew() async {
    if (widget.onAddNew == null || _isAdding) return;

    await hideKeyboard(context);
    if (!mounted) return;
    setState(() => _isAdding = true);

    try {
      await widget.onAddNew!();
      if (!mounted) return;
      _refreshItems();
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedItem = _resolveSelectedItem();

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
                    onPressed: _isAdding ? null : _handleAddNew,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
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
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.divider,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
            child: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSizes.xl),
                        child: Text(
                          'Sin resultados',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            final isSelected = selectedItem == item;
                            final leading = widget.leadingBuilder?.call(item);
                            return ListTile(
                              leading: leading,
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
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}
