import '../entities/asset_image.dart';
import '../repositories/asset_repository.dart';

class GetAssetImagesUseCase {
  GetAssetImagesUseCase(this._repository);

  final IAssetRepository _repository;

  Future<List<AssetImage>> call(String assetId) =>
      _repository.getImages(assetId);
}
