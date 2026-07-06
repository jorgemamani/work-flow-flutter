import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class UpdateAssetUseCase {
  UpdateAssetUseCase(this._repository);

  final IAssetRepository _repository;

  Future<Asset> call(Asset asset) => _repository.updateAsset(asset);
}
