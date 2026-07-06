import '../entities/asset_model_entity.dart';
import '../repositories/asset_catalog_repository.dart';

class GetModelsUseCase {
  GetModelsUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<List<AssetModelEntity>> call(String brandId) =>
      _repository.getModelsByBrand(brandId);
}
