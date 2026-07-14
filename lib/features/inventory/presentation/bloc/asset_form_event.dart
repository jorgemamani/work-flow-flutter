import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/warehouse_entity.dart';

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

class AssetFormConditionSelected extends AssetFormEvent {
  const AssetFormConditionSelected(this.condition);

  final ConditionEntity? condition;

  @override
  List<Object?> get props => [condition];
}

class AssetFormConditionCreated extends AssetFormEvent {
  const AssetFormConditionCreated({required this.name, required this.color});

  final String name;
  final String color;

  @override
  List<Object?> get props => [name, color];
}

class AssetFormPhotoAdded extends AssetFormEvent {
  const AssetFormPhotoAdded({
    required this.path,
    required this.contentType,
  });

  final String path;
  final String contentType;

  @override
  List<Object?> get props => [path, contentType];
}

class AssetFormPhotoRemoved extends AssetFormEvent {
  const AssetFormPhotoRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class AssetFormProjectSelected extends AssetFormEvent {
  const AssetFormProjectSelected(this.project);

  final ProjectEntity? project;

  @override
  List<Object?> get props => [project];
}

class AssetFormProjectCreated extends AssetFormEvent {
  const AssetFormProjectCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class AssetFormWarehouseSelected extends AssetFormEvent {
  const AssetFormWarehouseSelected(this.warehouse);

  final WarehouseEntity? warehouse;

  @override
  List<Object?> get props => [warehouse];
}

class AssetFormWarehouseCreated extends AssetFormEvent {
  const AssetFormWarehouseCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class AssetFormSubmitted extends AssetFormEvent {
  const AssetFormSubmitted(this.asset);

  final Asset asset;

  @override
  List<Object?> get props => [asset];
}
