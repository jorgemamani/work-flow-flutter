import '../entities/asset_brand.dart';
import '../repositories/asset_catalog_repository.dart';

class CreateBrandUseCase {
  CreateBrandUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<AssetBrand> call(String name) => _repository.createBrand(name);
}
