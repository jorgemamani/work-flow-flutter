import 'package:equatable/equatable.dart';

class WarehouseEntity extends Equatable {
  const WarehouseEntity({
    required this.id,
    required this.name,
    required this.type,
    this.projectId,
    this.address,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// "CENTRAL" | "ON_SITE"
  final String type;

  final String? projectId;
  final String? address;
  final bool isActive;

  bool get isCentral => type == 'CENTRAL';
  bool get isOnSite => type == 'ON_SITE';

  @override
  List<Object?> get props => [id, name, type, projectId, address, isActive];
}
