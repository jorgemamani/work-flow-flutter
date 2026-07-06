import '../entities/asset.dart';
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
}
