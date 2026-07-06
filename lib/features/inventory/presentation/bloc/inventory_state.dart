import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_type.dart';

enum InventoryStatus { initial, loading, success, failure }

class InventoryState extends Equatable {
  const InventoryState({
    this.status = InventoryStatus.initial,
    this.assets = const [],
    this.query = '',
    this.typeFilter,
    this.conditionFilter,
    this.errorMessage,
  });

  final InventoryStatus status;
  final List<Asset> assets;
  final String query;
  final AssetType? typeFilter;
  final AssetCondition? conditionFilter;
  final String? errorMessage;

  bool get hasActiveFilters =>
      typeFilter != null || conditionFilter != null || query.isNotEmpty;

  InventoryState copyWith({
    InventoryStatus? status,
    List<Asset>? assets,
    String? query,
    AssetType? Function()? typeFilter,
    AssetCondition? Function()? conditionFilter,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      query: query ?? this.query,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      conditionFilter:
          conditionFilter != null ? conditionFilter() : this.conditionFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        assets,
        query,
        typeFilter,
        conditionFilter,
        errorMessage,
      ];
}
