import 'package:flutter/material.dart';

/// Badge reutilizable de estado laboral del empleado.
/// Usar en Home, listado de compañeros, bitácora, etc.
///
/// Tamaño mínimo de touch target: 44 px (accesibilidad).
enum EmployeeStatus {
  enObra,
  enDescanso,
  sinAsignar;

  String get label => switch (this) {
        EmployeeStatus.enObra => 'En obra',
        EmployeeStatus.enDescanso => 'En descanso',
        EmployeeStatus.sinAsignar => 'Sin asignar',
      };

  Color get foreground => switch (this) {
        EmployeeStatus.enObra => const Color(0xFF065F46),
        EmployeeStatus.enDescanso => const Color(0xFF92400E),
        EmployeeStatus.sinAsignar => const Color(0xFF475569),
      };

  Color get background => switch (this) {
        EmployeeStatus.enObra => const Color(0xFFD1FAE5),
        EmployeeStatus.enDescanso => const Color(0xFFFEF3C7),
        EmployeeStatus.sinAsignar => const Color(0xFFF1F5F9),
      };

  IconData get icon => switch (this) {
        EmployeeStatus.enObra => Icons.construction_rounded,
        EmployeeStatus.enDescanso => Icons.coffee_rounded,
        EmployeeStatus.sinAsignar => Icons.person_off_outlined,
      };

  static EmployeeStatus fromBools({required bool enObra, required bool enDescanso}) {
    if (enObra) return EmployeeStatus.enObra;
    if (enDescanso) return EmployeeStatus.enDescanso;
    return EmployeeStatus.sinAsignar;
  }
}

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.compact = false,
  });

  final EmployeeStatus status;

  /// Si true, muestra ícono + texto. Si false, solo texto.
  final bool showIcon;

  /// Versión reducida (solo ícono + texto corto, sin padding extra).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vPad = compact ? 3.0 : 5.0;
    final hPad = compact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, color: status.foreground, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: status.foreground,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
