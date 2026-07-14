import 'dart:io';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/warehouse_entity.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_remote_datasource.dart';

class AssetRepositoryImpl implements IAssetRepository {
  AssetRepositoryImpl(this._remoteDataSource);

  final IAssetRemoteDataSource _remoteDataSource;

  @override
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    String? conditionId,
    String? location,
  }) async {
    var assets = await _remoteDataSource.getAssets(
      category: type?.apiCategory,
    );

    if (conditionId != null) {
      assets = assets.where((a) => a.conditionId == conditionId).toList();
    }

    if (location != null && location.isNotEmpty) {
      final q = location.toLowerCase();
      assets = assets
          .where((a) => (a.location ?? '').toLowerCase().contains(q))
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      assets = assets.where((a) {
        return a.description.toLowerCase().contains(q) ||
            (a.brandName ?? '').toLowerCase().contains(q) ||
            (a.modelName ?? '').toLowerCase().contains(q) ||
            (a.licensePlate ?? '').toLowerCase().contains(q) ||
            (a.serialNumber ?? '').toLowerCase().contains(q) ||
            (a.internalCode ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return assets;
  }

  @override
  Future<Asset?> getAssetById(String id) =>
      _remoteDataSource.getAssetById(id);

  @override
  Future<Asset> createAsset(Asset asset) {
    return _remoteDataSource.createAsset(_assetToBody(asset));
  }

  @override
  Future<Asset> updateAsset(Asset asset) {
    return _remoteDataSource.updateAsset(asset.id, _assetToBody(asset));
  }

  @override
  Future<void> deleteAsset(String id) => _remoteDataSource.deleteAsset(id);

  // ── Imágenes (flujo R2) ───────────────────────────────────────────────────

  @override
  Future<AssetImage> uploadImage({
    required String assetId,
    required File file,
    required String contentType,
    int sortOrder = 0,
  }) async {
    final presigned = await _remoteDataSource.presignImage(
      assetId: assetId,
      contentType: contentType,
    );

    await _remoteDataSource.uploadToR2(
      uploadUrl: presigned.uploadUrl,
      file: file,
      contentType: contentType,
    );

    return _remoteDataSource.confirmImage(
      assetId: assetId,
      key: presigned.key,
      publicUrl: presigned.publicUrl,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<List<AssetImage>> getImages(String assetId) =>
      _remoteDataSource.getImages(assetId);

  @override
  Future<void> deleteImage({
    required String assetId,
    required String imageId,
  }) =>
      _remoteDataSource.deleteImage(assetId: assetId, imageId: imageId);

  // ── Proyectos y almacenes ─────────────────────────────────────────────────

  @override
  Future<List<ProjectEntity>> getProjects() => _remoteDataSource.getProjects();

  @override
  Future<ProjectEntity> createProject(String name) =>
      _remoteDataSource.createProject(name);

  @override
  Future<List<WarehouseEntity>> getWarehouses() =>
      _remoteDataSource.getWarehouses();

  @override
  Future<WarehouseEntity> createWarehouse({
    required String name,
    required String type,
    String? projectId,
  }) =>
      _remoteDataSource.createWarehouse(
        name: name,
        type: type,
        projectId: projectId,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _assetToBody(Asset asset) {
    final isVehicle = asset.type == AssetType.vehicle;

    return {
      if (asset.modelId != null) 'modelId': asset.modelId,
      'internalCode': asset.internalCode ?? '',
      'description': asset.description,
      'quantity': asset.quantity,
      if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty)
        'serialNumber': asset.serialNumber,
      if (asset.color != null) 'color': asset.color,
      if (asset.observations != null) 'notes': asset.observations,
      if (asset.currentProjectId != null)
        'currentProjectId': asset.currentProjectId,
      if (asset.currentWarehouseId != null)
        'currentWarehouseId': asset.currentWarehouseId,
      if (asset.conditionId != null) 'conditionId': asset.conditionId,
      // Campos de vehículo: solo si el tipo local es VEHICLE.
      // La API valida contra la categoría del modelId — deben coincidir.
      if (isVehicle && asset.licensePlate != null)
        'licensePlate': asset.licensePlate,
      if (isVehicle && asset.year != null) 'year': asset.year,
      if (isVehicle && asset.engineNumber != null)
        'engineNumber': asset.engineNumber,
      if (isVehicle && asset.mileage != null) 'currentKm': asset.mileage,
      if (isVehicle && asset.vtvExpiry != null)
        'vtvExpiresAt': asset.vtvExpiry!.toIso8601String().substring(0, 10),
      if (isVehicle && asset.insuranceExpiry != null)
        'insuranceExpiresAt':
            asset.insuranceExpiry!.toIso8601String().substring(0, 10),
    };
  }
}
