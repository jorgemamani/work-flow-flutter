import 'package:equatable/equatable.dart';

/// Condición de activo persistida en la API (`/inventory/conditions`).
class ConditionEntity extends Equatable {
  const ConditionEntity({
    required this.id,
    required this.name,
    required this.color,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Color en formato hexadecimal, ej: `#4CAF50`.
  final String color;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, color, sortOrder, isActive];
}
