import '../entities/condition_entity.dart';
import '../repositories/asset_catalog_repository.dart';

class GetConditionsUseCase {
  GetConditionsUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<List<ConditionEntity>> call() => _repository.getConditions();
}
