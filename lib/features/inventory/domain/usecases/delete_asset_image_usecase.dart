import '../repositories/asset_repository.dart';

class DeleteAssetImageUseCase {
  DeleteAssetImageUseCase(this._repository);

  final IAssetRepository _repository;

  Future<void> call({
    required String assetId,
    required String imageId,
  }) =>
      _repository.deleteImage(assetId: assetId, imageId: imageId);
}
