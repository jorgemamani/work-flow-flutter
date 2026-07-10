import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';

abstract class AssetFormEvent extends Equatable {
  const AssetFormEvent();

  @override
  List<Object?> get props => [];
}

class AssetFormInitialized extends AssetFormEvent {
  const AssetFormInitialized({this.asset});

  final Asset? asset;

  @override
  List<Object?> get props => [asset];
}

class AssetFormTypeChanged extends AssetFormEvent {
  const AssetFormTypeChanged(this.type);

  final AssetType type;

  @override
  List<Object?> get props => [type];
}

class AssetFormBrandSelected extends AssetFormEvent {
  const AssetFormBrandSelected(this.brand);

  final AssetBrand? brand;

  @override
  List<Object?> get props => [brand];
}

class AssetFormModelSelected extends AssetFormEvent {
  const AssetFormModelSelected(this.model);

  final AssetModelEntity? model;

  @override
  List<Object?> get props => [model];
}

class AssetFormBrandCreated extends AssetFormEvent {
  const AssetFormBrandCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class AssetFormModelCreated extends AssetFormEvent {
  const AssetFormModelCreated({required this.brandId, required this.name});

  final String brandId;
  final String name;

  @override
  List<Object?> get props => [brandId, name];
}

class AssetFormPhotoAdded extends AssetFormEvent {
  const AssetFormPhotoAdded(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class AssetFormPhotoRemoved extends AssetFormEvent {
  const AssetFormPhotoRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Inicia la subida de todas las fotos pendientes para un activo ya creado.
class AssetFormImageUploadsStarted extends AssetFormEvent {
  const AssetFormImageUploadsStarted({required this.assetId});

  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

class AssetFormSubItemAdded extends AssetFormEvent {
  const AssetFormSubItemAdded(this.subItem);

  final AssetSubItem subItem;

  @override
  List<Object?> get props => [subItem];
}

class AssetFormSubItemUpdated extends AssetFormEvent {
  const AssetFormSubItemUpdated({required this.index, required this.subItem});

  final int index;
  final AssetSubItem subItem;

  @override
  List<Object?> get props => [index, subItem];
}

class AssetFormSubItemRemoved extends AssetFormEvent {
  const AssetFormSubItemRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class AssetFormConditionChanged extends AssetFormEvent {
  const AssetFormConditionChanged(this.condition);

  final AssetCondition condition;

  @override
  List<Object?> get props => [condition];
}

class AssetFormSubmitted extends AssetFormEvent {
  const AssetFormSubmitted(this.asset);

  final Asset asset;

  @override
  List<Object?> get props => [asset];
}
