import 'package:flutter/material.dart';

/// Convierte un color hexadecimal (`#RRGGBB` o `RRGGBB`) a [Color].
Color? colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final intVal = int.tryParse(value, radix: 16);
  if (intVal == null) return null;
  return Color(intVal);
}

/// Paleta sugerida para condiciones de activos.
const List<Color> kConditionPresetColors = [
  Color(0xFF4CAF50), // verde
  Color(0xFF2196F3), // azul
  Color(0xFFFFC107), // ámbar
  Color(0xFFFF9800), // naranja
  Color(0xFFF44336), // rojo
  Color(0xFF9C27B0), // violeta
  Color(0xFF607D8B), // gris azulado
  Color(0xFF795548), // marrón
];

String hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
