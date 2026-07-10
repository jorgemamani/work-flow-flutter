import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/repositories/asset_catalog_repository.dart';
import '../datasources/asset_remote_datasource.dart';

class AssetCatalogRepositoryImpl implements IAssetCatalogRepository {
  AssetCatalogRepositoryImpl(this._remoteDataSource);

  final IAssetRemoteDataSource _remoteDataSource;

  @override
  Future<List<AssetBrand>> getBrands() => _remoteDataSource.getBrands();

  @override
  Future<AssetBrand> createBrand(String name) =>
      _remoteDataSource.createBrand(name);

  @override
  Future<void> deleteBrand(String id) async {
    // La API actual no expone DELETE /brands individualmente;
    // se deja vacío para no romper el contrato.
  }

  @override
  Future<List<AssetModelEntity>> getModelsByBrand(String brandId) =>
      _remoteDataSource.getModels(brandId: brandId);

  @override
  Future<AssetModelEntity> createModel(String brandId, String name) =>
      _remoteDataSource.createModel(
        name: name,
        category: 'TOOL',
        brandId: brandId,
      );

  @override
  Future<void> deleteModel(String id) async {
    // Soft-delete manejado por la API; no expuesto desde el catálogo.
  }
}
