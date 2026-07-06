import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class CreateAssetUseCase {
  CreateAssetUseCase(this._repository);

  final IAssetRepository _repository;

  Future<Asset> call(Asset asset) => _repository.createAsset(asset);
}
