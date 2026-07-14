import 'dart:convert';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';

class AssetDbModel {
  const AssetDbModel({
    required this.id,
    required this.type,
    required this.description,
    this.brandId,
    this.brandName,
    this.modelId,
    this.modelName,
    this.serialNumber,
    this.color,
    required this.quantity,
    this.location,
    this.conditionId,
    this.conditionName,
    this.conditionColor,
    this.observations,
    required this.photoPaths,
    this.licensePlate,
    this.year,
    this.engineNumber,
    this.chassisNumber,
    this.mileage,
    this.vtvExpiry,
    this.insuranceExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String description;
  final String? brandId;
  final String? brandName;
  final String? modelId;
  final String? modelName;
  final String? serialNumber;
  final String? color;
  final int quantity;
  final String? location;
  final String? conditionId;
  final String? conditionName;
  final String? conditionColor;
  final String? observations;
  final String photoPaths; // JSON array
  final String? licensePlate;
  final int? year;
  final String? engineNumber;
  final String? chassisNumber;
  final int? mileage;
  final String? vtvExpiry;
  final String? insuranceExpiry;
  final String createdAt;
  final String updatedAt;

  factory AssetDbModel.fromMap(Map<String, dynamic> map) {
    return AssetDbModel(
      id: map['id'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      brandId: map['brand_id'] as String?,
      brandName: map['brand_name'] as String?,
      modelId: map['model_id'] as String?,
      modelName: map['model_name'] as String?,
      serialNumber: map['serial_number'] as String?,
      color: map['color'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      location: map['location'] as String?,
      conditionId: map['condition_id'] as String?,
      conditionName: map['condition_name'] as String?,
      conditionColor: map['condition_color'] as String?,
      observations: map['observations'] as String?,
      photoPaths: map['photo_paths'] as String? ?? '[]',
      licensePlate: map['license_plate'] as String?,
      year: map['year'] as int?,
      engineNumber: map['engine_number'] as String?,
      chassisNumber: map['chassis_number'] as String?,
      mileage: map['mileage'] as int?,
      vtvExpiry: map['vtv_expiry'] as String?,
      insuranceExpiry: map['insurance_expiry'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'description': description,
        'brand_id': brandId,
        'brand_name': brandName,
        'model_id': modelId,
        'model_name': modelName,
        'serial_number': serialNumber,
        'color': color,
        'quantity': quantity,
        'location': location,
        'condition_id': conditionId,
        'condition_name': conditionName,
        'condition_color': conditionColor,
        'observations': observations,
        'photo_paths': photoPaths,
        'license_plate': licensePlate,
        'year': year,
        'engine_number': engineNumber,
        'chassis_number': chassisNumber,
        'mileage': mileage,
        'vtv_expiry': vtvExpiry,
        'insurance_expiry': insuranceExpiry,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Asset toEntity({List<AssetSubItem> subItems = const []}) {
    return Asset(
      id: id,
      type: _typeFromString(type),
      description: description,
      brandId: brandId,
      brandName: brandName,
      modelId: modelId,
      modelName: modelName,
      serialNumber: serialNumber,
      color: color,
      quantity: quantity,
      location: location,
      conditionId: conditionId,
      conditionName: conditionName,
      conditionColor: conditionColor,
      observations: observations,
      photoPaths: List<String>.from(jsonDecode(photoPaths) as List),
      subItems: subItems,
      licensePlate: licensePlate,
      year: year,
      engineNumber: engineNumber,
      chassisNumber: chassisNumber,
      mileage: mileage,
      vtvExpiry: vtvExpiry != null ? DateTime.tryParse(vtvExpiry!) : null,
      insuranceExpiry:
          insuranceExpiry != null ? DateTime.tryParse(insuranceExpiry!) : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  factory AssetDbModel.fromEntity(Asset entity) {
    return AssetDbModel(
      id: entity.id,
      type: entity.type.name,
      description: entity.description,
      brandId: entity.brandId,
      brandName: entity.brandName,
      modelId: entity.modelId,
      modelName: entity.modelName,
      serialNumber: entity.serialNumber,
      color: entity.color,
      quantity: entity.quantity,
      location: entity.location,
      conditionId: entity.conditionId,
      conditionName: entity.conditionName,
      conditionColor: entity.conditionColor,
      observations: entity.observations,
      photoPaths: jsonEncode(entity.photoPaths),
      licensePlate: entity.licensePlate,
      year: entity.year,
      engineNumber: entity.engineNumber,
      chassisNumber: entity.chassisNumber,
      mileage: entity.mileage,
      vtvExpiry: entity.vtvExpiry?.toIso8601String(),
      insuranceExpiry: entity.insuranceExpiry?.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  static AssetType _typeFromString(String value) {
    return AssetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetType.tool,
    );
  }
}
