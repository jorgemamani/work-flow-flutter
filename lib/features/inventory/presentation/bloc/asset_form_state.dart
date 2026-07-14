import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/warehouse_entity.dart';

enum AssetFormStatus { initial, loading, success, failure }

enum PhotoUploadStatus { pending, uploading, confirmed, error }

class AssetPhotoEntry extends Equatable {
  const AssetPhotoEntry({
    required this.localPath,
    this.contentType = 'image/jpeg',
    this.status = PhotoUploadStatus.pending,
    this.remoteImage,
    this.errorMessage,
  });

  final String localPath;
  final String contentType;
  final PhotoUploadStatus status;
  final AssetImage? remoteImage;
  final String? errorMessage;

  bool get isPending => status == PhotoUploadStatus.pending;
  bool get isUploading => status == PhotoUploadStatus.uploading;
  bool get isConfirmed => status == PhotoUploadStatus.confirmed;
  bool get hasError => status == PhotoUploadStatus.error;

  String get displayUrl => remoteImage?.url ?? localPath;

  AssetPhotoEntry copyWith({
    PhotoUploadStatus? status,
    AssetImage? remoteImage,
    String? errorMessage,
    String? contentType,
  }) {
    return AssetPhotoEntry(
      localPath: localPath,
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      remoteImage: remoteImage ?? this.remoteImage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [localPath, contentType, status, remoteImage, errorMessage];
}

class AssetFormState extends Equatable {
  const AssetFormState({
    this.status = AssetFormStatus.initial,
    this.selectedType = AssetType.tool,
    this.brands = const [],
    this.models = const [],
    this.selectedBrand,
    this.selectedModel,
    this.conditions = const [],
    this.selectedCondition,
    this.projects = const [],
    this.selectedProject,
    this.warehouses = const [],
    this.selectedWarehouse,
    this.photos = const [],
    this.savedAsset,
    this.errorMessage,
    this.isLoadingCatalogs = false,
    this.isLoadingModels = false,
  });

  final AssetFormStatus status;
  final AssetType selectedType;
  final List<AssetBrand> brands;
  final List<AssetModelEntity> models;
  final AssetBrand? selectedBrand;
  final AssetModelEntity? selectedModel;

  final List<ConditionEntity> conditions;
  final ConditionEntity? selectedCondition;

  final List<ProjectEntity> projects;
  final ProjectEntity? selectedProject;

  final List<WarehouseEntity> warehouses;
  final WarehouseEntity? selectedWarehouse;

  final List<AssetPhotoEntry> photos;
  final Asset? savedAsset;
  final String? errorMessage;

  final bool isLoadingCatalogs;
  final bool isLoadingModels;

  List<String> get photoPaths => photos.map((p) => p.localPath).toList();

  bool get hasPendingPhotos => photos.any(
        (p) =>
            p.status == PhotoUploadStatus.pending ||
            p.status == PhotoUploadStatus.error,
      );

  bool get isUploadingPhotos =>
      photos.any((p) => p.status == PhotoUploadStatus.uploading);

  AssetFormState copyWith({
    AssetFormStatus? status,
    AssetType? selectedType,
    List<AssetBrand>? brands,
    List<AssetModelEntity>? models,
    AssetBrand? Function()? selectedBrand,
    AssetModelEntity? Function()? selectedModel,
    List<ConditionEntity>? conditions,
    ConditionEntity? Function()? selectedCondition,
    List<ProjectEntity>? projects,
    ProjectEntity? Function()? selectedProject,
    List<WarehouseEntity>? warehouses,
    WarehouseEntity? Function()? selectedWarehouse,
    List<AssetPhotoEntry>? photos,
    Asset? savedAsset,
    String? Function()? errorMessage,
    bool? isLoadingCatalogs,
    bool? isLoadingModels,
  }) {
    return AssetFormState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      brands: brands ?? this.brands,
      models: models ?? this.models,
      selectedBrand:
          selectedBrand != null ? selectedBrand() : this.selectedBrand,
      selectedModel:
          selectedModel != null ? selectedModel() : this.selectedModel,
      conditions: conditions ?? this.conditions,
      selectedCondition: selectedCondition != null
          ? selectedCondition()
          : this.selectedCondition,
      projects: projects ?? this.projects,
      selectedProject:
          selectedProject != null ? selectedProject() : this.selectedProject,
      warehouses: warehouses ?? this.warehouses,
      selectedWarehouse:
          selectedWarehouse != null
              ? selectedWarehouse()
              : this.selectedWarehouse,
      photos: photos ?? this.photos,
      savedAsset: savedAsset ?? this.savedAsset,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      isLoadingCatalogs: isLoadingCatalogs ?? this.isLoadingCatalogs,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedType,
        brands,
        models,
        selectedBrand,
        selectedModel,
        conditions,
        selectedCondition,
        projects,
        selectedProject,
        warehouses,
        selectedWarehouse,
        photos,
        savedAsset,
        errorMessage,
        isLoadingCatalogs,
        isLoadingModels,
      ];
}
