import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../../../../shared/utils/color_utils.dart';
import '../../domain/entities/asset_type.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_type_theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const InventoryLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Inventario',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (!state.hasActiveFilters) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  context
                      .read<InventoryBloc>()
                      .add(const InventoryFiltersCleared());
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchCtrl),
          _FilterChips(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _AssetList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(RouteNames.assetForm),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Cargar activo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: (v) => context
            .read<InventoryBloc>()
            .add(InventorySearchChanged(v)),
        decoration: InputDecoration(
          hintText: 'Buscar por descripción, marca, patente, N° serie...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    context
                        .read<InventoryBloc>()
                        .add(const InventorySearchChanged(''));
                  },
                )
              : null,
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
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            children: [
              // Type filters
              ...AssetType.values.map((t) {
                final selected = state.typeFilter == t;
                final color = AssetTypeTheme.colorFor(t);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: FilterChip(
                    avatar: Icon(
                      AssetTypeTheme.iconFor(t),
                      size: 14,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                    label: Text(t.label),
                    selected: selected,
                    onSelected: (_) => context.read<InventoryBloc>().add(
                          InventoryTypeFilterChanged(selected ? null : t),
                        ),
                    selectedColor: color.withValues(alpha: 0.15),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected ? color : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected ? color : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),

              const SizedBox(width: AppSizes.sm),

              // Condition filters
              ...state.conditions.map((c) {
                final selected = state.conditionFilterId == c.id;
                final color = colorFromHex(c.color) ?? AppColors.textSecondary;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: FilterChip(
                    label: Text(c.name),
                    selected: selected,
                    onSelected: (_) => context.read<InventoryBloc>().add(
                          InventoryConditionFilterChanged(
                              selected ? null : c.id),
                        ),
                    selectedColor: color.withValues(alpha: 0.15),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected ? color : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected ? color : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Asset list ────────────────────────────────────────────────────────────────

class _AssetList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state.status == InventoryStatus.loading &&
            state.assets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == InventoryStatus.failure) {
          return _ErrorView(
            message: state.errorMessage ?? 'Error al cargar el inventario',
            onRetry: () => context
                .read<InventoryBloc>()
                .add(const InventoryLoadRequested()),
          );
        }

        if (state.assets.isEmpty) {
          return _EmptyView(hasFilters: state.hasActiveFilters);
        }

        return RefreshIndicator(
          onRefresh: () async => context
              .read<InventoryBloc>()
              .add(const InventoryLoadRequested()),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSizes.sm,
              bottom: 100, // FAB clearance
            ),
            itemCount: state.assets.length,
            itemBuilder: (_, i) {
              final asset = state.assets[i];
              return AssetCard(
                asset: asset,
                onTap: () => context.push(
                  RouteNames.assetDetail,
                  extra: asset,
                ),
                onEdit: () => context.push(
                  RouteNames.assetForm,
                  extra: asset,
                ),
                onDelete: () => _confirmDelete(context, asset.id),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String assetId) {
    final inventoryBloc = context.read<InventoryBloc>();
    AlertManager.showConfirmSheet(
      title: 'Eliminar activo',
      description: '¿Estás seguro? Esta acción no se puede deshacer.',
      options: [
        SheetOption(
          label: 'Eliminar',
          onTap: () =>
              inventoryBloc.add(InventoryAssetDeleted(assetId)),
          isDestructive: true,
        ),
        SheetOption(
          label: 'Cancelar',
          onTap: () {},
          style: SheetOptionStyle.outlined,
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off_rounded
                : Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            hasFilters
                ? 'Sin resultados para los filtros aplicados'
                : 'Aún no hay activos cargados',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasFilters) ...[
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Toca "Cargar activo" para comenzar',
              style: TextStyle(
                  color: AppColors.textDisabled, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: AppSizes.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
