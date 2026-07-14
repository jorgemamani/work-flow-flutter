import '../entities/asset.dart';
import '../entities/asset_type.dart';
import '../repositories/asset_repository.dart';

class GetAssetsUseCase {
  GetAssetsUseCase(this._repository);

  final IAssetRepository _repository;

  Future<List<Asset>> call({
    String? query,
    AssetType? type,
    String? conditionId,
    String? location,
  }) {
    return _repository.getAssets(
      query: query,
      type: type,
      conditionId: conditionId,
      location: location,
    );
  }
}
