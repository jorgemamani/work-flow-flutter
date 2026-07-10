import 'dart:io';

import '../entities/asset.dart';
import '../entities/asset_image.dart';
import '../entities/asset_type.dart';
import '../entities/asset_condition.dart';

abstract class IAssetRepository {
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    AssetCondition? condition,
    String? location,
  });

  Future<Asset?> getAssetById(String id);

  Future<Asset> createAsset(Asset asset);

  Future<Asset> updateAsset(Asset asset);

  Future<void> deleteAsset(String id);

  // ── Imágenes ───────────────────────────────────────────────────────────────

  /// Ejecuta el flujo completo: presign → PUT R2 → confirm.
  /// Lanza si el PUT a R2 falla — en ese caso NO llama a confirm.
  Future<AssetImage> uploadImage({
    required String assetId,
    required File file,
    required String contentType,
    int sortOrder = 0,
  });

  Future<List<AssetImage>> getImages(String assetId);

  Future<void> deleteImage({required String assetId, required String imageId});
}
