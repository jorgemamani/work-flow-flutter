import 'package:equatable/equatable.dart';

import 'asset_condition.dart';
import 'asset_sub_item.dart';
import 'asset_type.dart';

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.type,
    required this.description,
    this.brandId,
    this.brandName,
    this.modelId,
    this.modelName,
    this.serialNumber,
    this.color,
    this.quantity = 1,
    this.location,
    this.condition = AssetCondition.good,
    this.observations,
    this.photoPaths = const [],
    this.subItems = const [],
    // Vehicle-specific
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
  final AssetType type;
  final String description;

  // Catálogo dinámico
  final String? brandId;
  final String? brandName;
  final String? modelId;
  final String? modelName;

  final String? serialNumber;
  final String? color;
  final int quantity;
  final String? location;
  final AssetCondition condition;
  final String? observations;
  final List<String> photoPaths;

  /// Solo para tipo [AssetType.toolBox]
  final List<AssetSubItem> subItems;

  // ── Campos exclusivos de vehículo ──
  final String? licensePlate;
  final int? year;
  final String? engineNumber;
  final String? chassisNumber;
  final int? mileage;
  final DateTime? vtvExpiry;
  final DateTime? insuranceExpiry;

  final DateTime createdAt;
  final DateTime updatedAt;

  Asset copyWith({
    String? id,
    AssetType? type,
    String? description,
    String? brandId,
    String? brandName,
    String? modelId,
    String? modelName,
    String? serialNumber,
    String? color,
    int? quantity,
    String? location,
    AssetCondition? condition,
    String? observations,
    List<String>? photoPaths,
    List<AssetSubItem>? subItems,
    String? licensePlate,
    int? year,
    String? engineNumber,
    String? chassisNumber,
    int? mileage,
    DateTime? vtvExpiry,
    DateTime? insuranceExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      observations: observations ?? this.observations,
      photoPaths: photoPaths ?? this.photoPaths,
      subItems: subItems ?? this.subItems,
      licensePlate: licensePlate ?? this.licensePlate,
      year: year ?? this.year,
      engineNumber: engineNumber ?? this.engineNumber,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      mileage: mileage ?? this.mileage,
      vtvExpiry: vtvExpiry ?? this.vtvExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        description,
        brandId,
        brandName,
        modelId,
        modelName,
        serialNumber,
        color,
        quantity,
        location,
        condition,
        observations,
        photoPaths,
        subItems,
        licensePlate,
        year,
        engineNumber,
        chassisNumber,
        mileage,
        vtvExpiry,
        insuranceExpiry,
        createdAt,
        updatedAt,
      ];
}
