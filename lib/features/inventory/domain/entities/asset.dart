import 'package:equatable/equatable.dart';

import 'asset_image.dart';
import 'asset_sub_item.dart';
import 'asset_type.dart';

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.type,
    required this.description,
    this.internalCode,
    this.brandId,
    this.brandName,
    this.modelId,
    this.modelName,
    this.serialNumber,
    this.color,
    this.quantity = 1,
    this.location,
    this.currentProjectId,
    this.currentProjectName,
    this.currentWarehouseId,
    this.currentWarehouseName,
    this.conditionId,
    this.conditionName,
    this.conditionColor,
    this.observations,
    this.photoPaths = const [],
    this.images = const [],
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
  final String? internalCode;

  final String? brandId;
  final String? brandName;
  final String? modelId;
  final String? modelName;

  final String? serialNumber;
  final String? color;
  final int quantity;
  final String? location;

  final String? currentProjectId;
  final String? currentProjectName;
  final String? currentWarehouseId;
  final String? currentWarehouseName;

  /// Condición persistida en API (`/inventory/conditions`).
  final String? conditionId;
  final String? conditionName;
  final String? conditionColor;

  final String? observations;
  final List<String> photoPaths;
  final List<AssetImage> images;
  final List<AssetSubItem> subItems;

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
    String? Function()? internalCode,
    String? brandId,
    String? brandName,
    String? modelId,
    String? modelName,
    String? serialNumber,
    String? color,
    int? quantity,
    String? location,
    String? Function()? currentProjectId,
    String? Function()? currentProjectName,
    String? Function()? currentWarehouseId,
    String? Function()? currentWarehouseName,
    String? Function()? conditionId,
    String? Function()? conditionName,
    String? Function()? conditionColor,
    String? observations,
    List<String>? photoPaths,
    List<AssetImage>? images,
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
      internalCode:
          internalCode != null ? internalCode() : this.internalCode,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      currentProjectId:
          currentProjectId != null ? currentProjectId() : this.currentProjectId,
      currentProjectName:
          currentProjectName != null
              ? currentProjectName()
              : this.currentProjectName,
      currentWarehouseId:
          currentWarehouseId != null
              ? currentWarehouseId()
              : this.currentWarehouseId,
      currentWarehouseName:
          currentWarehouseName != null
              ? currentWarehouseName()
              : this.currentWarehouseName,
      conditionId:
          conditionId != null ? conditionId() : this.conditionId,
      conditionName:
          conditionName != null ? conditionName() : this.conditionName,
      conditionColor:
          conditionColor != null ? conditionColor() : this.conditionColor,
      observations: observations ?? this.observations,
      photoPaths: photoPaths ?? this.photoPaths,
      images: images ?? this.images,
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
        internalCode,
        brandId,
        brandName,
        modelId,
        modelName,
        serialNumber,
        color,
        quantity,
        location,
        currentProjectId,
        currentProjectName,
        currentWarehouseId,
        currentWarehouseName,
        conditionId,
        conditionName,
        conditionColor,
        observations,
        photoPaths,
        images,
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
