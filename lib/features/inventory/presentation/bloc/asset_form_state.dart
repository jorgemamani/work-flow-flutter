import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';

enum AssetFormStatus { initial, loading, success, failure }

/// Estado de una foto individual durante el flujo de subida a R2.
enum PhotoUploadStatus {
  /// Foto seleccionada localmente, aún no subida.
  pending,

  /// PUT a R2 en curso.
  uploading,

  /// Confirmada en el backend — `remoteUrl` disponible.
  confirmed,

  /// PUT a R2 o confirmación fallaron.
  error,
}

/// Representa una foto en el formulario de activo.
/// Puede estar pendiente (solo ruta local) o confirmada (URL remota).
class AssetPhotoEntry extends Equatable {
  const AssetPhotoEntry({
    required this.localPath,
    this.status = PhotoUploadStatus.pending,
    this.remoteImage,
    this.errorMessage,
  });

  /// Ruta local en el dispositivo (del `image_picker`).
  final String localPath;

  final PhotoUploadStatus status;

  /// Disponible solo cuando `status == confirmed`.
  final AssetImage? remoteImage;

  final String? errorMessage;

  bool get isPending => status == PhotoUploadStatus.pending;
  bool get isUploading => status == PhotoUploadStatus.uploading;
  bool get isConfirmed => status == PhotoUploadStatus.confirmed;
  bool get hasError => status == PhotoUploadStatus.error;

  /// URL a mostrar en la UI (remota si está confirmada, local si no).
  String get displayUrl => remoteImage?.url ?? localPath;

  AssetPhotoEntry copyWith({
    PhotoUploadStatus? status,
    AssetImage? remoteImage,
    String? errorMessage,
  }) {
    return AssetPhotoEntry(
      localPath: localPath,
      status: status ?? this.status,
      remoteImage: remoteImage ?? this.remoteImage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [localPath, status, remoteImage, errorMessage];
}

class AssetFormState extends Equatable {
  const AssetFormState({
    this.status = AssetFormStatus.initial,
    this.selectedType = AssetType.tool,
    this.brands = const [],
    this.models = const [],
    this.selectedBrand,
    this.selectedModel,
    this.photos = const [],
    this.savedAsset,
    this.errorMessage,
  });

  final AssetFormStatus status;
  final AssetType selectedType;
  final List<AssetBrand> brands;
  final List<AssetModelEntity> models;
  final AssetBrand? selectedBrand;
  final AssetModelEntity? selectedModel;

  /// Lista unificada de fotos (pendientes + confirmadas).
  final List<AssetPhotoEntry> photos;

  final Asset? savedAsset;
  final String? errorMessage;

  /// Rutas locales (compat. con widgets que aún usan `photoPaths`).
  List<String> get photoPaths => photos.map((p) => p.localPath).toList();

  /// ¿Hay fotos pendientes de subir?
  bool get hasPendingPhotos =>
      photos.any((p) => p.status == PhotoUploadStatus.pending);

  /// ¿Alguna foto está subiendo en este momento?
  bool get isUploadingPhotos =>
      photos.any((p) => p.status == PhotoUploadStatus.uploading);

  AssetFormState copyWith({
    AssetFormStatus? status,
    AssetType? selectedType,
    List<AssetBrand>? brands,
    List<AssetModelEntity>? models,
    AssetBrand? Function()? selectedBrand,
    AssetModelEntity? Function()? selectedModel,
    List<AssetPhotoEntry>? photos,
    Asset? savedAsset,
    String? Function()? errorMessage,
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
      photos: photos ?? this.photos,
      savedAsset: savedAsset ?? this.savedAsset,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
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
        photos,
        savedAsset,
        errorMessage,
      ];
}
