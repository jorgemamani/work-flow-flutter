import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';

enum AssetFormStatus { initial, loading, success, failure }

class AssetFormState extends Equatable {
  const AssetFormState({
    this.status = AssetFormStatus.initial,
    this.selectedType = AssetType.tool,
    this.brands = const [],
    this.models = const [],
    this.selectedBrand,
    this.selectedModel,
    this.photoPaths = const [],
    this.savedAsset,
    this.errorMessage,
  });

  final AssetFormStatus status;
  final AssetType selectedType;
  final List<AssetBrand> brands;
  final List<AssetModelEntity> models;
  final AssetBrand? selectedBrand;
  final AssetModelEntity? selectedModel;
  final List<String> photoPaths;
  final Asset? savedAsset;
  final String? errorMessage;

  AssetFormState copyWith({
    AssetFormStatus? status,
    AssetType? selectedType,
    List<AssetBrand>? brands,
    List<AssetModelEntity>? models,
    AssetBrand? Function()? selectedBrand,
    AssetModelEntity? Function()? selectedModel,
    List<String>? photoPaths,
    Asset? savedAsset,
    String? errorMessage,
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
      photoPaths: photoPaths ?? this.photoPaths,
      savedAsset: savedAsset ?? this.savedAsset,
      errorMessage: errorMessage ?? this.errorMessage,
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
        photoPaths,
        savedAsset,
        errorMessage,
      ];
}
