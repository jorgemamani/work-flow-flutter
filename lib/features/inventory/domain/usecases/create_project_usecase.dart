import '../entities/project_entity.dart';
import '../repositories/asset_repository.dart';

class CreateProjectUseCase {
  CreateProjectUseCase(this._repository);

  final IAssetRepository _repository;

  Future<ProjectEntity> call(String name) => _repository.createProject(name);
}
