import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';
import '../../domain/usecases/create_asset_usecase.dart';
import '../../domain/usecases/create_brand_usecase.dart';
import '../../domain/usecases/create_condition_usecase.dart';
import '../../domain/usecases/create_model_usecase.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/create_warehouse_usecase.dart';
import '../../domain/usecases/delete_asset_image_usecase.dart';
import '../../domain/usecases/get_asset_images_usecase.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_conditions_usecase.dart';
import '../../domain/usecases/get_models_usecase.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/usecases/update_asset_usecase.dart';
import '../../domain/usecases/upload_asset_image_usecase.dart';
import 'asset_form_event.dart';
import 'asset_form_state.dart';

class AssetFormBloc extends Bloc<AssetFormEvent, AssetFormState> {
  AssetFormBloc({
    required GetBrandsUseCase getBrandsUseCase,
    required CreateBrandUseCase createBrandUseCase,
    required GetModelsUseCase getModelsUseCase,
    required CreateModelUseCase createModelUseCase,
    required GetConditionsUseCase getConditionsUseCase,
    required CreateConditionUseCase createConditionUseCase,
    required GetProjectsUseCase getProjectsUseCase,
    required CreateProjectUseCase createProjectUseCase,
    required GetWarehousesUseCase getWarehousesUseCase,
    required CreateWarehouseUseCase createWarehouseUseCase,
    required CreateAssetUseCase createAssetUseCase,
    required UpdateAssetUseCase updateAssetUseCase,
    required UploadAssetImageUseCase uploadAssetImageUseCase,
    required DeleteAssetImageUseCase deleteAssetImageUseCase,
    required GetAssetImagesUseCase getAssetImagesUseCase,
  })  : _getBrands = getBrandsUseCase,
        _createBrand = createBrandUseCase,
        _getModels = getModelsUseCase,
        _createModel = createModelUseCase,
        _getConditions = getConditionsUseCase,
        _createCondition = createConditionUseCase,
        _getProjects = getProjectsUseCase,
        _createProject = createProjectUseCase,
        _getWarehouses = getWarehousesUseCase,
        _createWarehouse = createWarehouseUseCase,
        _createAsset = createAssetUseCase,
        _updateAsset = updateAssetUseCase,
        _uploadImage = uploadAssetImageUseCase,
        _deleteImage = deleteAssetImageUseCase,
        _getImages = getAssetImagesUseCase,
        super(const AssetFormState()) {
    on<AssetFormInitialized>(_onInitialized);
    on<AssetFormTypeChanged>(_onTypeChanged);
    on<AssetFormBrandSelected>(_onBrandSelected);
    on<AssetFormModelSelected>(_onModelSelected);
    on<AssetFormBrandCreated>(_onBrandCreated);
    on<AssetFormModelCreated>(_onModelCreated);
    on<AssetFormConditionSelected>(_onConditionSelected);
    on<AssetFormConditionCreated>(_onConditionCreated);
    on<AssetFormProjectSelected>(_onProjectSelected);
    on<AssetFormProjectCreated>(_onProjectCreated);
    on<AssetFormWarehouseSelected>(_onWarehouseSelected);
    on<AssetFormWarehouseCreated>(_onWarehouseCreated);
    on<AssetFormPhotoAdded>(_onPhotoAdded);
    on<AssetFormPhotoRemoved>(_onPhotoRemoved);
    on<AssetFormSubmitted>(_onSubmitted);
  }

  final GetBrandsUseCase _getBrands;
  final CreateBrandUseCase _createBrand;
  final GetModelsUseCase _getModels;
  final CreateModelUseCase _createModel;
  final GetConditionsUseCase _getConditions;
  final CreateConditionUseCase _createCondition;
  final GetProjectsUseCase _getProjects;
  final CreateProjectUseCase _createProject;
  final GetWarehousesUseCase _getWarehouses;
  final CreateWarehouseUseCase _createWarehouse;
  final CreateAssetUseCase _createAsset;
  final UpdateAssetUseCase _updateAsset;
  final UploadAssetImageUseCase _uploadImage;
  final DeleteAssetImageUseCase _deleteImage;
  final GetAssetImagesUseCase _getImages;

  /// Evita race conditions al cambiar marca/tipo rápidamente.
  int _modelsLoadGeneration = 0;

  Future<void> _onInitialized(
    AssetFormInitialized event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(
      status: AssetFormStatus.loading,
      isLoadingCatalogs: true,
    ));

    final type = event.asset?.type ?? AssetType.tool;

    // Cada catálogo se carga de forma independiente: un fallo no bloquea el resto.
    final brands = await _safeLoad(() => _getBrands(), 'marcas', emit);
    final conditions =
        await _safeLoad(() => _getConditions(), 'condiciones', emit);
    final projects = await _safeLoad(() => _getProjects(), 'proyectos', emit);
    final warehouses =
        await _safeLoad(() => _getWarehouses(), 'almacenes', emit);

    conditions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final selectedBrand = event.asset?.brandId != null
        ? brands.where((b) => b.id == event.asset!.brandId).firstOrNull
        : null;

    ConditionEntity? selectedCondition;
    if (event.asset?.conditionId != null) {
      selectedCondition = conditions
          .where((c) => c.id == event.asset!.conditionId)
          .firstOrNull;
      selectedCondition ??= ConditionEntity(
        id: event.asset!.conditionId!,
        name: event.asset!.conditionName ?? 'Condición',
        color: event.asset!.conditionColor ?? '#9E9E9E',
      );
    }

    final selectedProject = event.asset?.currentProjectId != null
        ? projects
            .where((p) => p.id == event.asset!.currentProjectId)
            .firstOrNull
        : null;

    final selectedWarehouse = event.asset?.currentWarehouseId != null
        ? warehouses
            .where((w) => w.id == event.asset!.currentWarehouseId)
            .firstOrNull
        : null;

    List<AssetImage> assetImages = [];
    if (event.asset?.id != null && event.asset!.id.isNotEmpty) {
      try {
        assetImages = await _getImages(event.asset!.id);
      } catch (_) {}
    }

    final photos = assetImages
        .map(
          (img) => AssetPhotoEntry(
            localPath: img.url,
            status: PhotoUploadStatus.confirmed,
            remoteImage: img,
          ),
        )
        .toList();

    emit(state.copyWith(
      status: AssetFormStatus.initial,
      isLoadingCatalogs: false,
      selectedType: type,
      brands: brands,
      conditions: conditions,
      projects: projects,
      warehouses: warehouses,
      selectedBrand: () => selectedBrand,
      selectedCondition: () => selectedCondition,
      selectedProject: () => selectedProject,
      selectedWarehouse: () => selectedWarehouse,
      photos: photos,
    ));

    if (selectedBrand != null) {
      final models = await _loadModelsForBrand(selectedBrand.id, type);
      AssetModelEntity? selectedModel;
      if (event.asset?.modelId != null) {
        selectedModel =
            models.where((m) => m.id == event.asset!.modelId).firstOrNull;
      }
      emit(state.copyWith(
        models: models,
        selectedModel: () => selectedModel,
      ));
    }
  }

  Future<List<T>> _safeLoad<T>(
    Future<List<T>> Function() loader,
    String label,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      return await loader();
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'No se pudieron cargar $label. Reintentá.',
      ));
      return [];
    }
  }

  Future<void> _onTypeChanged(
    AssetFormTypeChanged event,
    Emitter<AssetFormState> emit,
  ) async {
    final brandId = state.selectedBrand?.id;
    emit(state.copyWith(
      selectedType: event.type,
      selectedModel: () => null,
      models: const [],
      isLoadingModels: brandId != null,
    ));
    await _reloadModels(emit, brandId: brandId, type: event.type);
  }

  Future<void> _onBrandSelected(
    AssetFormBrandSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(
      selectedBrand: () => event.brand,
      selectedModel: () => null,
    ));
    await _reloadModels(
      emit,
      brandId: event.brand?.id,
      type: state.selectedType,
    );
  }

  Future<void> _reloadModels(
    Emitter<AssetFormState> emit, {
    required String? brandId,
    required AssetType type,
  }) async {
    if (brandId == null) {
      emit(state.copyWith(models: const [], isLoadingModels: false));
      return;
    }

    final generation = ++_modelsLoadGeneration;
    emit(state.copyWith(isLoadingModels: true, models: const []));

    try {
      final models = await _loadModelsForBrand(brandId, type);
      if (generation != _modelsLoadGeneration) return;
      emit(state.copyWith(models: models, isLoadingModels: false));
    } catch (e) {
      if (generation != _modelsLoadGeneration) return;
      emit(state.copyWith(
        isLoadingModels: false,
        errorMessage: () => 'No se pudieron cargar los modelos.',
      ));
    }
  }

  Future<void> _onModelSelected(
    AssetFormModelSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(selectedModel: () => event.model));
  }

  Future<void> _onConditionSelected(
    AssetFormConditionSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(selectedCondition: () => event.condition));
  }

  Future<void> _onConditionCreated(
    AssetFormConditionCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final condition = await _createCondition(
        name: event.name,
        color: event.color,
        sortOrder: state.conditions.length,
      );
      final conditions = [...state.conditions, condition];
      conditions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(state.copyWith(
        conditions: conditions,
        selectedCondition: () => condition,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  Future<void> _onBrandCreated(
    AssetFormBrandCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final brand = await _createBrand(event.name);
      final brands = [...state.brands, brand];
      brands.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        brands: brands,
        selectedBrand: () => brand,
        selectedModel: () => null,
        models: const [],
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  Future<void> _onModelCreated(
    AssetFormModelCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final model = await _createModel(
        brandId: event.brandId,
        name: event.name,
        category: state.selectedType.apiCategory,
      );
      final models = [...state.models, model];
      models.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        models: models,
        selectedModel: () => model,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  Future<void> _onProjectSelected(
    AssetFormProjectSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(
      selectedProject: () => event.project,
      selectedWarehouse: () => null,
    ));
  }

  Future<void> _onProjectCreated(
    AssetFormProjectCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final project = await _createProject(event.name);
      final projects = [...state.projects, project];
      projects.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        projects: projects,
        selectedProject: () => project,
        selectedWarehouse: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  Future<void> _onWarehouseSelected(
    AssetFormWarehouseSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(selectedWarehouse: () => event.warehouse));
  }

  Future<void> _onWarehouseCreated(
    AssetFormWarehouseCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final warehouse = await _createWarehouse(
        name: event.name,
        type: state.selectedProject != null ? 'ON_SITE' : 'CENTRAL',
        projectId: state.selectedProject?.id,
      );
      final warehouses = [...state.warehouses, warehouse];
      warehouses.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        warehouses: warehouses,
        selectedWarehouse: () => warehouse,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  void _onPhotoAdded(
    AssetFormPhotoAdded event,
    Emitter<AssetFormState> emit,
  ) {
    emit(state.copyWith(
      photos: [
        ...state.photos,
        AssetPhotoEntry(
          localPath: event.path,
          contentType: event.contentType,
        ),
      ],
    ));
  }

  Future<void> _onPhotoRemoved(
    AssetFormPhotoRemoved event,
    Emitter<AssetFormState> emit,
  ) async {
    final photo = state.photos[event.index];

    if (photo.isConfirmed && photo.remoteImage != null) {
      try {
        await _deleteImage(
          assetId: photo.remoteImage!.assetId,
          imageId: photo.remoteImage!.id,
        );
      } catch (_) {}
    }

    final updated = List<AssetPhotoEntry>.from(state.photos)
      ..removeAt(event.index);
    emit(state.copyWith(photos: updated));
  }

  Future<void> _onSubmitted(
    AssetFormSubmitted event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(status: AssetFormStatus.loading));
    try {
      final Asset saved;
      final alreadyCreatedId =
          event.asset.id.isEmpty ? state.savedAsset?.id : null;

      if (alreadyCreatedId != null) {
        saved = await _updateAsset(event.asset.copyWith(id: alreadyCreatedId));
      } else if (event.asset.id.isEmpty) {
        saved = await _createAsset(event.asset);
      } else {
        saved = await _updateAsset(event.asset);
      }

      emit(state.copyWith(savedAsset: saved));

      final failedCount = await _uploadPendingPhotos(saved.id, emit);

      if (failedCount > 0) {
        final detail = state.photos
            .where((p) => p.hasError && p.errorMessage != null)
            .map((p) => p.errorMessage!)
            .firstOrNull;
        emit(state.copyWith(
          status: AssetFormStatus.failure,
          errorMessage: () => detail != null
              ? 'El activo se guardó, pero $failedCount foto(s) no se '
                  'pudieron subir: $detail'
              : 'El activo se guardó, pero $failedCount foto(s) no se '
                  'pudieron subir. Tocá "Guardar" para reintentar.',
        ));
        return;
      }

      emit(state.copyWith(status: AssetFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AssetFormStatus.failure,
        errorMessage: () => e.toString(),
      ));
    }
  }

  Future<int> _uploadPendingPhotos(
    String assetId,
    Emitter<AssetFormState> emit,
  ) async {
    if (!state.hasPendingPhotos) return 0;

    final photos = List<AssetPhotoEntry>.from(state.photos);
    var nextSortOrder = photos.where((p) => p.isConfirmed).length;
    var failedCount = 0;

    for (var i = 0; i < photos.length; i++) {
      if (!photos[i].isPending && !photos[i].hasError) continue;

      photos[i] = photos[i].copyWith(status: PhotoUploadStatus.uploading);
      emit(state.copyWith(photos: List.unmodifiable(photos)));

      try {
        final file = File(photos[i].localPath);
        if (!await file.exists()) {
          throw const ServerException(
            message: 'No se encontró el archivo de imagen en el dispositivo.',
          );
        }

        final contentType = photos[i].contentType;

        final confirmedImage = await _uploadImage(
          assetId: assetId,
          file: file,
          contentType: contentType,
          sortOrder: nextSortOrder,
        );

        photos[i] = photos[i].copyWith(
          status: PhotoUploadStatus.confirmed,
          remoteImage: confirmedImage,
          errorMessage: null,
        );
        nextSortOrder++;
      } catch (e) {
        final message =
            e is AppException ? e.message : 'Error al subir la imagen';
        photos[i] = photos[i].copyWith(
          status: PhotoUploadStatus.error,
          errorMessage: message,
        );
        failedCount++;
      }

      emit(state.copyWith(photos: List.unmodifiable(photos)));
    }

    return failedCount;
  }

  Future<List<AssetModelEntity>> _loadModelsForBrand(
    String brandId,
    AssetType type,
  ) async {
    final models = await _getModels(brandId);
    return models.where((m) => m.category == type.apiCategory).toList();
  }
}
