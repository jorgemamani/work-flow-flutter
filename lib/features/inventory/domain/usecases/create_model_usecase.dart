import '../entities/asset_model_entity.dart';
import '../repositories/asset_catalog_repository.dart';

class CreateModelUseCase {
  CreateModelUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<AssetModelEntity> call({
    required String brandId,
    required String name,
    required String category,
  }) =>
      _repository.createModel(
        brandId: brandId,
        name: name,
        category: category,
      );
}
