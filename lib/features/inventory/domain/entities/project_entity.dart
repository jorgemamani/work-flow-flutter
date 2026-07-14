import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  const ProjectEntity({
    required this.id,
    required this.name,
    this.location,
    this.clientCompany,
    this.status = 'ACTIVE',
  });

  final String id;
  final String name;
  final String? location;
  final String? clientCompany;

  /// "ACTIVE" | "COMPLETED"
  final String status;

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [id, name, location, clientCompany, status];
}
