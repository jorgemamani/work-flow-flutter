import '../domain/entities/bitacora_entry.dart';

/// TODO(workflow): Reemplazar por llamada real a la API cuando esté disponible.
/// Buscar: BITACORA-MOCK.
class MockBitacoraDataSource {
  static List<BitacoraEntry> getAll() => _entries;

  static List<BitacoraEntry> getByEmpleado(String empleadoId) =>
      _entries.where((e) => e.empleadoId == empleadoId).toList();

  static List<BitacoraEntry> getByObra(String obraId) =>
      _entries.where((e) => e.obraId == obraId).toList();
}

final _now = DateTime.now();

final List<BitacoraEntry> _entries = [
  BitacoraEntry(
    id: 'b1',
    fecha: _now,
    obraId: 'obra-mina-san-jose',
    obraNombre: 'Mina San José',
    empleadoId: 'mock-empleado',
    empleadoNombre: 'Juan Pérez',
    descripcion: 'Instalación de soportes en el nivel 3. Sin inconvenientes.',
    tareas: ['Instalación de soportes', 'Revisión de ventilación', 'Reporte de turno'],
  ),
  BitacoraEntry(
    id: 'b2',
    fecha: _now.subtract(const Duration(days: 1)),
    obraId: 'obra-mina-san-jose',
    obraNombre: 'Mina San José',
    empleadoId: 'mock-empleado',
    empleadoNombre: 'Juan Pérez',
    descripcion: 'Mantenimiento preventivo de equipos de perforación.',
    tareas: ['Mantenimiento de taladros', 'Chequeo de cables'],
  ),
  BitacoraEntry(
    id: 'b3',
    fecha: _now,
    obraId: 'obra-mina-san-jose',
    obraNombre: 'Mina San José',
    empleadoId: 'c2',
    empleadoNombre: 'María González',
    descripcion: 'Calibración de sensores de temperatura en el túnel principal.',
    tareas: ['Calibración de sensores', 'Actualización de planilla de control'],
  ),
  BitacoraEntry(
    id: 'b4',
    fecha: _now.subtract(const Duration(days: 1)),
    obraId: 'obra-mina-san-jose',
    obraNombre: 'Mina San José',
    empleadoId: 'c3',
    empleadoNombre: 'Pedro Sánchez',
    descripcion: 'Operación de carretilla en zona de extracción.',
    tareas: ['Operación de equipos pesados', 'Señalización de zona'],
  ),
  BitacoraEntry(
    id: 'b5',
    fecha: _now,
    obraId: 'obra-refineria',
    obraNombre: 'Refinería Central',
    empleadoId: 'c11',
    empleadoNombre: 'Diego Fuentes',
    descripcion: 'Supervisión del turno nocturno sin incidentes.',
    tareas: ['Supervisión de turno', 'Reporte a gerencia'],
  ),
  BitacoraEntry(
    id: 'b6',
    fecha: _now.subtract(const Duration(days: 2)),
    obraId: 'obra-planta-norte',
    obraNombre: 'Planta Norte',
    empleadoId: 'c20',
    empleadoNombre: 'Sofía Morales',
    descripcion: 'Revisión de sistemas hidráulicos de la grúa principal.',
    tareas: ['Inspección hidráulica', 'Registro de mantenimiento'],
  ),
];
