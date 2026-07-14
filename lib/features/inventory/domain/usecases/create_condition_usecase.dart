import '../entities/condition_entity.dart';
import '../repositories/asset_catalog_repository.dart';

class CreateConditionUseCase {
  CreateConditionUseCase(this._repository);

  final IAssetCatalogRepository _repository;

  Future<ConditionEntity> call({
    required String name,
    required String color,
    int? sortOrder,
  }) =>
      _repository.createCondition(
        name: name,
        color: color,
        sortOrder: sortOrder,
      );
}
