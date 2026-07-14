import '../../domain/entities/asset_model_entity.dart';

class AssetModelDbModel {
  const AssetModelDbModel({
    required this.id,
    required this.brandId,
    required this.name,
  });

  final String id;
  final String brandId;
  final String name;

  factory AssetModelDbModel.fromMap(Map<String, dynamic> map) {
    return AssetModelDbModel(
      id: map['id'] as String,
      brandId: map['brand_id'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand_id': brandId,
        'name': name,
      };

  AssetModelEntity toEntity() => AssetModelEntity(
        id: id,
        brandId: brandId,
        name: name,
        category: 'TOOL',
      );

  factory AssetModelDbModel.fromEntity(AssetModelEntity entity) =>
      AssetModelDbModel(
        id: entity.id,
        brandId: entity.brandId,
        name: entity.name,
      );
}
