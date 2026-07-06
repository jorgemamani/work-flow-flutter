import '../../domain/entities/asset_brand.dart';

class AssetBrandDbModel {
  const AssetBrandDbModel({required this.id, required this.name});

  final String id;
  final String name;

  factory AssetBrandDbModel.fromMap(Map<String, dynamic> map) {
    return AssetBrandDbModel(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  AssetBrand toEntity() => AssetBrand(id: id, name: name);

  factory AssetBrandDbModel.fromEntity(AssetBrand entity) =>
      AssetBrandDbModel(id: entity.id, name: entity.name);
}
