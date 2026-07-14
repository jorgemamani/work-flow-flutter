import 'package:equatable/equatable.dart';

class AssetModelEntity extends Equatable {
  const AssetModelEntity({
    required this.id,
    required this.brandId,
    required this.name,
    required this.category,
  });

  final String id;
  final String brandId;
  final String name;

  /// Categoría API del modelo (VEHICLE, TOOL, etc.).
  final String category;

  @override
  List<Object?> get props => [id, brandId, name, category];
}
