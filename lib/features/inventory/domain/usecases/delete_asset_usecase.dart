import '../repositories/asset_repository.dart';

class DeleteAssetUseCase {
  DeleteAssetUseCase(this._repository);

  final IAssetRepository _repository;

  Future<void> call(String id) => _repository.deleteAsset(id);
}
