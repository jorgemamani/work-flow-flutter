import 'package:equatable/equatable.dart';

import 'asset_condition.dart';

class AssetSubItem extends Equatable {
  const AssetSubItem({
    required this.id,
    required this.assetId,
    required this.description,
    this.brandName,
    this.serialNumber,
    this.color,
    this.quantity = 1,
    this.condition = AssetCondition.good,
    this.observations,
    this.sortOrder = 0,
  });

  final String id;
  final String assetId;
  final String description;
  final String? brandName;
  final String? serialNumber;
  final String? color;
  final int quantity;
  final AssetCondition condition;
  final String? observations;
  final int sortOrder;

  AssetSubItem copyWith({
    String? id,
    String? assetId,
    String? description,
    String? brandName,
    String? serialNumber,
    String? color,
    int? quantity,
    AssetCondition? condition,
    String? observations,
    int? sortOrder,
  }) {
    return AssetSubItem(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      description: description ?? this.description,
      brandName: brandName ?? this.brandName,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      observations: observations ?? this.observations,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        assetId,
        description,
        brandName,
        serialNumber,
        color,
        quantity,
        condition,
        observations,
        sortOrder,
      ];
}
