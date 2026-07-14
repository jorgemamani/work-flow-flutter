import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';

enum InventoryStatus { initial, loading, success, failure }

class InventoryState extends Equatable {
  const InventoryState({
    this.status = InventoryStatus.initial,
    this.assets = const [],
    this.conditions = const [],
    this.query = '',
    this.typeFilter,
    this.conditionFilterId,
    this.errorMessage,
  });

  final InventoryStatus status;
  final List<Asset> assets;
  final List<ConditionEntity> conditions;
  final String query;
  final AssetType? typeFilter;
  final String? conditionFilterId;
  final String? errorMessage;

  bool get hasActiveFilters =>
      typeFilter != null || conditionFilterId != null || query.isNotEmpty;

  InventoryState copyWith({
    InventoryStatus? status,
    List<Asset>? assets,
    List<ConditionEntity>? conditions,
    String? query,
    AssetType? Function()? typeFilter,
    String? Function()? conditionFilterId,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      conditions: conditions ?? this.conditions,
      query: query ?? this.query,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      conditionFilterId: conditionFilterId != null
          ? conditionFilterId()
          : this.conditionFilterId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        assets,
        conditions,
        query,
        typeFilter,
        conditionFilterId,
        errorMessage,
      ];
}
