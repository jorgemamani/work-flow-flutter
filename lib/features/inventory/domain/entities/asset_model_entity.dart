import 'package:equatable/equatable.dart';

class AssetModelEntity extends Equatable {
  const AssetModelEntity({
    required this.id,
    required this.brandId,
    required this.name,
  });

  final String id;
  final String brandId;
  final String name;

  @override
  List<Object?> get props => [id, brandId, name];
}
