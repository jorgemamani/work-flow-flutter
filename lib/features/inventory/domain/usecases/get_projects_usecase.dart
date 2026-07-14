import '../entities/project_entity.dart';
import '../repositories/asset_repository.dart';

class GetProjectsUseCase {
  GetProjectsUseCase(this._repository);

  final IAssetRepository _repository;

  Future<List<ProjectEntity>> call() => _repository.getProjects();
}
