import 'package:flutter/material.dart';

/// Marca de Workflow: base neutra fija para todas las empresas. El color de
/// cada empresa es el acento ([TenantBrand]: botón principal, lo elegido, el
/// foco, el avance); lo que significa algo (texto, estados, avisos, la franja
/// sin conexión) sale de acá y es igual para todos.
class AppColors {
  AppColors._();

  /// Tinta: el texto, la chapa, la franja sin conexión.
  static const Color ink = Color(0xFF16181A);
  static const Color primary = ink;

  /// Piedra: fondo de las pantallas.
  static const Color backgroundLight = Color(0xFFF6F5F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5C5F5C);
  static const Color textSoft = textSecondary;
  static const Color textDisabled = Color(0xFFA9ABA6);

  /// Línea entre filas y bordes de tarjetas.
  static const Color border = Color(0xFFE4E2DC);

  /// Borde de campos y de opciones sin elegir.
  static const Color lineStrong = Color(0xFFC9C7C1);

  /// Fondo de lo elegido sin tinta (pestañas, avisos neutros).
  static const Color selected = Color(0xFFEAE8E3);

  /// Botón principal deshabilitado.
  static const Color disabledFill = Color(0xFFD9D7D1);

  /// Estados: siempre punto + texto, nunca pastilla de color.
  static const Color statusSuccess = Color(0xFF2C7A47);
  static const Color statusWarning = Color(0xFF97570A);
  static const Color statusError = Color(0xFFB8321C);
  static const Color statusMove = Color(0xFF2B59C3);
  static const Color statusNeutral = Color(0xFF6B6E6A);
  static const Color error = statusError;

  /// Avisos en tinta (snackbars).
  static const Color statusInfo = ink;

  /// Punto de la franja sin conexión (sobre tinta).
  static const Color offlineDot = Color(0xFFF2B544);

  /// Fondo del escáner.
  static const Color scannerBackground = Color(0xFF0E0F10);
}
