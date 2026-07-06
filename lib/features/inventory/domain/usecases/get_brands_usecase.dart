import '../entities/asset_brand.dart';
import '../repositories/asset_catalog_repository.dart';

class GetBrandsUseCase {
  GetBrandsUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<List<AssetBrand>> call() => _repository.getBrands();
}
