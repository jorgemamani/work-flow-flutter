import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_sub_item.dart';

class AssetSubItemDbModel {
  const AssetSubItemDbModel({
    required this.id,
    required this.assetId,
    required this.description,
    this.brandName,
    this.serialNumber,
    this.color,
    required this.quantity,
    required this.condition,
    this.observations,
    required this.sortOrder,
  });

  final String id;
  final String assetId;
  final String description;
  final String? brandName;
  final String? serialNumber;
  final String? color;
  final int quantity;
  final String condition;
  final String? observations;
  final int sortOrder;

  factory AssetSubItemDbModel.fromMap(Map<String, dynamic> map) {
    return AssetSubItemDbModel(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      description: map['description'] as String,
      brandName: map['brand_name'] as String?,
      serialNumber: map['serial_number'] as String?,
      color: map['color'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      condition: map['condition'] as String? ?? 'good',
      observations: map['observations'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'asset_id': assetId,
        'description': description,
        'brand_name': brandName,
        'serial_number': serialNumber,
        'color': color,
        'quantity': quantity,
        'condition': condition,
        'observations': observations,
        'sort_order': sortOrder,
      };

  AssetSubItem toEntity() {
    return AssetSubItem(
      id: id,
      assetId: assetId,
      description: description,
      brandName: brandName,
      serialNumber: serialNumber,
      color: color,
      quantity: quantity,
      condition: _conditionFromString(condition),
      observations: observations,
      sortOrder: sortOrder,
    );
  }

  factory AssetSubItemDbModel.fromEntity(AssetSubItem entity) {
    return AssetSubItemDbModel(
      id: entity.id,
      assetId: entity.assetId,
      description: entity.description,
      brandName: entity.brandName,
      serialNumber: entity.serialNumber,
      color: entity.color,
      quantity: entity.quantity,
      condition: entity.condition.name,
      observations: entity.observations,
      sortOrder: entity.sortOrder,
    );
  }

  static AssetCondition _conditionFromString(String value) {
    return AssetCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetCondition.good,
    );
  }
}
