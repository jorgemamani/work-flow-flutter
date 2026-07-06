import '../entities/asset_brand.dart';
import '../entities/asset_model_entity.dart';

abstract class IAssetCatalogRepository {
  // Brands
  Future<List<AssetBrand>> getBrands();
  Future<AssetBrand> createBrand(String name);
  Future<void> deleteBrand(String id);

  // Models
  Future<List<AssetModelEntity>> getModelsByBrand(String brandId);
  Future<AssetModelEntity> createModel(String brandId, String name);
  Future<void> deleteModel(String id);
}
