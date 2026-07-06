import 'package:equatable/equatable.dart';

class AssetBrand extends Equatable {
  const AssetBrand({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
