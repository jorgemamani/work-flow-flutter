import '../entities/warehouse_entity.dart';
import '../repositories/asset_repository.dart';

class GetWarehousesUseCase {
  GetWarehousesUseCase(this._repository);

  final IAssetRepository _repository;

  Future<List<WarehouseEntity>> call() => _repository.getWarehouses();
}
