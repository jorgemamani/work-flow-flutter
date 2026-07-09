import 'dart:io';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_remote_datasource.dart';

class AssetRepositoryImpl implements IAssetRepository {
  AssetRepositoryImpl(this._remoteDataSource);

  final IAssetRemoteDataSource _remoteDataSource;

  @override
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    AssetCondition? condition,
    String? location,
  }) =>
      _remoteDataSource.getAssets(
        category: type?.apiCategory,
      );

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
    // Paso 1: obtener URL firmada
    final presigned = await _remoteDataSource.presignImage(
      assetId: assetId,
      contentType: contentType,
    );

    // Paso 2: PUT directo a R2 — si falla, lanza excepción y NO confirma
    await _remoteDataSource.uploadToR2(
      uploadUrl: presigned.uploadUrl,
      file: file,
      contentType: contentType,
    );

    // Paso 3: confirmar en la API (solo si el PUT fue exitoso)
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _assetToBody(Asset asset) {
    return {
      if (asset.modelId != null) 'modelId': asset.modelId,
      if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty)
        'internalCode': asset.serialNumber,
      'description': asset.description,
      'quantity': asset.quantity,
      if (asset.serialNumber != null) 'serialNumber': asset.serialNumber,
      if (asset.color != null) 'color': asset.color,
      if (asset.observations != null) 'notes': asset.observations,
      // Vehículo
      if (asset.licensePlate != null) 'licensePlate': asset.licensePlate,
      if (asset.year != null) 'year': asset.year,
      if (asset.engineNumber != null) 'engineNumber': asset.engineNumber,
      if (asset.mileage != null) 'currentKm': asset.mileage,
      if (asset.vtvExpiry != null)
        'vtvExpiresAt': asset.vtvExpiry!.toIso8601String().substring(0, 10),
      if (asset.insuranceExpiry != null)
        'insuranceExpiresAt':
            asset.insuranceExpiry!.toIso8601String().substring(0, 10),
    };
  }
}
