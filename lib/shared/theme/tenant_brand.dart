import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// El color de la empresa es el acento de la app: botones principales, lo
/// elegido, el foco y el avance. La empresa carga uno solo (`brandColor` de
/// `/auth/me`) y de acá sale el resto, con la misma cuenta que la web
/// (`workflow-frontend/src/shared/utils/brandColor.ts`).
///
/// Lo que significa algo no cambia: el texto en tinta, los estados con punto
/// + texto, la chapa y la franja sin conexión.
@immutable
class TenantBrand extends ThemeExtension<TenantBrand> {
  const TenantBrand({required this.fill, required this.on, required this.ink});

  /// El color tal cual: rellenos (botón principal, lo elegido, la tarjeta del
  /// proyecto, la marca de la empresa).
  final Color fill;

  /// Texto encima del relleno: tinta o blanco, el que dé más contraste.
  final Color on;

  /// Para texto, bordes y marcadores finos sobre la piedra (≥ 4,5:1).
  final Color ink;

  /// Petróleo de Workflow: la empresa no cargó color.
  static const fallbackHex = '#0E6E85';
  static final fallback = TenantBrand.from(fallbackHex);

  static final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  factory TenantBrand.from(String? hex) {
    final value = hex != null && _hex.hasMatch(hex) ? hex : fallbackHex;
    final fill = Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
    return TenantBrand(
      fill: fill,
      on: contrastRatio(fill, AppColors.ink) >= contrastRatio(fill, Colors.white) ? AppColors.ink : Colors.white,
      ink: _adjustToContrast(fill, AppColors.backgroundLight, 4.5),
    );
  }

  /// Contraste WCAG entre dos colores (1 a 21).
  static double contrastRatio(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static double _channel(int c) {
    final v = c / 255;
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _luminance(Color c) {
    final argb = c.toARGB32();
    return 0.2126 * _channel((argb >> 16) & 0xFF) + 0.7152 * _channel((argb >> 8) & 0xFF) + 0.0722 * _channel(argb & 0xFF);
  }

  /// Baja (o sube) la luminosidad HSL de a 0,005 hasta llegar al contraste.
  static Color _adjustToContrast(Color color, Color bg, double target) {
    if (contrastRatio(color, bg) >= target) return color;
    final (h, s, l) = _toHsl(color);
    final step = _luminance(bg) > 0.5 ? -0.005 : 0.005;
    for (var next = l; next >= 0 && next <= 1; next += step) {
      final candidate = _fromHsl(h, s, next);
      if (contrastRatio(candidate, bg) >= target) return candidate;
    }
    return _luminance(bg) > 0.5 ? AppColors.ink : Colors.white;
  }

  static (double, double, double) _toHsl(Color c) {
    final argb = c.toARGB32();
    final r = ((argb >> 16) & 0xFF) / 255;
    final g = ((argb >> 8) & 0xFF) / 255;
    final b = (argb & 0xFF) / 255;
    final mx = math.max(r, math.max(g, b));
    final mn = math.min(r, math.min(g, b));
    final l = (mx + mn) / 2;
    if (mx == mn) return (0, 0, l);
    final d = mx - mn;
    final s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    final h = mx == r ? (g - b) / d + (g < b ? 6 : 0) : (mx == g ? (b - r) / d + 2 : (r - g) / d + 4);
    return (h / 6, s, l);
  }

  static Color _fromHsl(double h, double s, double l) {
    int byte(double v) => (v * 255).round().clamp(0, 255);
    if (s == 0) return Color.fromARGB(255, byte(l), byte(l), byte(l));
    double hue(double p, double q, double t) {
      final tt = t < 0 ? t + 1 : (t > 1 ? t - 1 : t);
      if (tt < 1 / 6) return p + (q - p) * 6 * tt;
      if (tt < 1 / 2) return q;
      if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
      return p;
    }

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    return Color.fromARGB(255, byte(hue(p, q, h + 1 / 3)), byte(hue(p, q, h)), byte(hue(p, q, h - 1 / 3)));
  }

  @override
  TenantBrand copyWith({Color? fill, Color? on, Color? ink}) =>
      TenantBrand(fill: fill ?? this.fill, on: on ?? this.on, ink: ink ?? this.ink);

  @override
  TenantBrand lerp(TenantBrand? other, double t) {
    if (other == null) return this;
    return TenantBrand(
      fill: Color.lerp(fill, other.fill, t)!,
      on: t < 0.5 ? on : other.on,
      ink: Color.lerp(ink, other.ink, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TenantBrand && other.fill == fill && other.on == on && other.ink == ink;

  @override
  int get hashCode => Object.hash(fill, on, ink);
}

extension TenantBrandX on BuildContext {
  /// El acento de la empresa actual (petróleo si no cargó color).
  TenantBrand get brand => Theme.of(this).extension<TenantBrand>() ?? TenantBrand.fallback;
}
