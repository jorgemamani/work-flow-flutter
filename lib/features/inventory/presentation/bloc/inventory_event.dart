import 'package:equatable/equatable.dart';

import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_type.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class InventoryLoadRequested extends InventoryEvent {
  const InventoryLoadRequested();
}

class InventorySearchChanged extends InventoryEvent {
  const InventorySearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class InventoryTypeFilterChanged extends InventoryEvent {
  const InventoryTypeFilterChanged(this.type);

  final AssetType? type;

  @override
  List<Object?> get props => [type];
}

class InventoryConditionFilterChanged extends InventoryEvent {
  const InventoryConditionFilterChanged(this.condition);

  final AssetCondition? condition;

  @override
  List<Object?> get props => [condition];
}

class InventoryFiltersCleared extends InventoryEvent {
  const InventoryFiltersCleared();
}

class InventoryAssetDeleted extends InventoryEvent {
  const InventoryAssetDeleted(this.assetId);

  final String assetId;

  @override
  List<Object?> get props => [assetId];
}
