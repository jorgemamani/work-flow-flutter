import 'package:flutter/material.dart';

/// IBM Plex empaquetada en `assets/fonts/` (la app tiene que andar sin señal):
/// Sans para el texto, Mono para códigos, cantidades, fechas y horas.
class AppFonts {
  AppFonts._();

  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static TextStyle monoStyle({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        // Cifras alineadas en listas y contadores.
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
