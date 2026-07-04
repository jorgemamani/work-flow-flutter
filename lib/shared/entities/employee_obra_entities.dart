import 'package:equatable/equatable.dart';

enum ObraProductStatus {
  operativo,
  enUso,
  mantenimiento,
  averiado;

  String get label => switch (this) {
        ObraProductStatus.operativo => 'Operativo',
        ObraProductStatus.enUso => 'En uso',
        ObraProductStatus.mantenimiento => 'Mantenimiento',
        ObraProductStatus.averiado => 'Averiado',
      };

  static ObraProductStatus fromApi(String? value) {
    final v = value?.toLowerCase().trim().replaceAll(' ', '_') ?? '';
    switch (v) {
      case 'operativo':
      case 'ok':
        return ObraProductStatus.operativo;
      case 'en_uso':
      case 'enuso':
        return ObraProductStatus.enUso;
      case 'mantenimiento':
        return ObraProductStatus.mantenimiento;
      case 'averiado':
        return ObraProductStatus.averiado;
      default:
        return ObraProductStatus.operativo;
    }
  }
}

class ObraColleague extends Equatable {
  const ObraColleague({
    required this.id,
    required this.nombre,
    required this.puesto,
  });

  final String id;
  final String nombre;
  final String puesto;

  factory ObraColleague.fromJson(Map<String, dynamic> json) {
    return ObraColleague(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      puesto: json['puesto'] as String? ?? json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'puesto': puesto,
      };

  @override
  List<Object?> get props => [id, nombre, puesto];
}

class ObraProduct extends Equatable {
  const ObraProduct({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.status,
  });

  final String id;
  final String nombre;
  final int cantidad;
  final ObraProductStatus status;

  factory ObraProduct.fromJson(Map<String, dynamic> json) {
    return ObraProduct(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      status: ObraProductStatus.fromApi(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'cantidad': cantidad,
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, nombre, cantidad, status];
}

class ObraAssignment extends Equatable {
  const ObraAssignment({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.supervisorNombre,
    required this.companeros,
    required this.productos,
  });

  final String id;
  final String nombre;
  final String ubicacion;
  final String supervisorNombre;
  final List<ObraColleague> companeros;
  final List<ObraProduct> productos;

  factory ObraAssignment.fromJson(Map<String, dynamic> json) {
    return ObraAssignment(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? '',
      ubicacion: json['ubicacion'] as String? ?? json['location'] as String? ?? '',
      supervisorNombre: json['supervisor_nombre'] as String? ??
          json['supervisor'] as String? ??
          '',
      companeros: (json['companeros'] as List<dynamic>? ??
              json['colleagues'] as List<dynamic>? ??
              const [])
          .map((e) => ObraColleague.fromJson(e as Map<String, dynamic>))
          .toList(),
      productos: (json['productos'] as List<dynamic>? ??
              json['products'] as List<dynamic>? ??
              const [])
          .map((e) => ObraProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'ubicacion': ubicacion,
        'supervisor_nombre': supervisorNombre,
        'companeros': companeros.map((e) => e.toJson()).toList(),
        'productos': productos.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [id, nombre, ubicacion, supervisorNombre, companeros, productos];
}
