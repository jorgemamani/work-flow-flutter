import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/repositories/asset_catalog_repository.dart';
import '../datasources/asset_local_datasource.dart';

class AssetCatalogRepositoryImpl implements IAssetCatalogRepository {
  AssetCatalogRepositoryImpl(this._localDataSource);

  final IAssetLocalDataSource _localDataSource;

  @override
  Future<List<AssetBrand>> getBrands() => _localDataSource.getBrands();

  @override
  Future<AssetBrand> createBrand(String name) =>
      _localDataSource.createBrand(name);

  @override
  Future<void> deleteBrand(String id) => _localDataSource.deleteBrand(id);

  @override
  Future<List<AssetModelEntity>> getModelsByBrand(String brandId) =>
      _localDataSource.getModelsByBrand(brandId);

  @override
  Future<AssetModelEntity> createModel(String brandId, String name) =>
      _localDataSource.createModel(brandId, name);

  @override
  Future<void> deleteModel(String id) => _localDataSource.deleteModel(id);
}
