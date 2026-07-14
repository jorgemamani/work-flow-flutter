import '../entities/asset_brand.dart';
import '../entities/asset_model_entity.dart';
import '../entities/condition_entity.dart';

abstract class IAssetCatalogRepository {
  // Brands
  Future<List<AssetBrand>> getBrands();
  Future<AssetBrand> createBrand(String name);
  Future<void> deleteBrand(String id);

  // Models
  Future<List<AssetModelEntity>> getModelsByBrand(String brandId);
  Future<AssetModelEntity> createModel({
    required String brandId,
    required String name,
    required String category,
  });
  Future<void> deleteModel(String id);

  // Conditions
  Future<List<ConditionEntity>> getConditions();
  Future<ConditionEntity> createCondition({
    required String name,
    required String color,
    int? sortOrder,
  });
}
