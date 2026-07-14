import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class GetAssetByIdUseCase {
  GetAssetByIdUseCase(this._repository);

  final IAssetRepository _repository;

  Future<Asset?> call(String id) => _repository.getAssetById(id);
}
