import 'package:equatable/equatable.dart';

/// Entrada de la bitácora. Estructura flexible para campos futuros.
class BitacoraEntry extends Equatable {
  const BitacoraEntry({
    required this.id,
    required this.fecha,
    required this.obraId,
    required this.obraNombre,
    required this.empleadoId,
    required this.empleadoNombre,
    required this.descripcion,
    this.tareas = const [],
    this.extraData = const {},
  });

  final String id;
  final DateTime fecha;
  final String obraId;
  final String obraNombre;
  final String empleadoId;
  final String empleadoNombre;
  final String descripcion;

  /// Lista de tareas realizadas (extensible).
  final List<String> tareas;

  /// Espacio para campos futuros sin romper el modelo.
  final Map<String, dynamic> extraData;

  String get fechaLabel {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    if (_sameDay(fecha, hoy)) return 'Hoy';
    if (_sameDay(fecha, ayer)) return 'Ayer';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  List<Object?> get props =>
      [id, fecha, obraId, empleadoId, descripcion, tareas];
}
