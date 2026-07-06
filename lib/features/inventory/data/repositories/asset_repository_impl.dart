import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_local_datasource.dart';

class AssetRepositoryImpl implements IAssetRepository {
  AssetRepositoryImpl(this._localDataSource);

  final IAssetLocalDataSource _localDataSource;

  @override
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    AssetCondition? condition,
    String? location,
  }) =>
      _localDataSource.getAssets(
        query: query,
        type: type,
        condition: condition,
        location: location,
      );

  @override
  Future<Asset?> getAssetById(String id) =>
      _localDataSource.getAssetById(id);

  @override
  Future<Asset> createAsset(Asset asset) =>
      _localDataSource.createAsset(asset);

  @override
  Future<Asset> updateAsset(Asset asset) =>
      _localDataSource.updateAsset(asset);

  @override
  Future<void> deleteAsset(String id) => _localDataSource.deleteAsset(id);
}
