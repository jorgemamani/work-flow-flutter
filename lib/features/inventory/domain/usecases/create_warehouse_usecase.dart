import '../entities/warehouse_entity.dart';
import '../repositories/asset_repository.dart';

class CreateWarehouseUseCase {
  CreateWarehouseUseCase(this._repository);

  final IAssetRepository _repository;

  Future<WarehouseEntity> call({
    required String name,
    required String type,
    String? projectId,
  }) =>
      _repository.createWarehouse(name: name, type: type, projectId: projectId);
}
