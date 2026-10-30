import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_flow/shared/constants/app_colors.dart';
import 'package:work_flow/shared/theme/tenant_brand.dart';
import 'package:work_flow/shared/utils/color_utils.dart';

void main() {
  test('Arqytop: texto en tinta, ink oscurecido hasta 4,5:1 sobre la piedra', () {
    final b = TenantBrand.from('#54B548');
    expect(hexFromColor(b.fill), '#54B548');
    expect(b.on, AppColors.ink);
    expect(hexFromColor(b.ink), '#3B7E32');
  });

  test('amarillo: texto en tinta, ink #876C00', () {
    final b = TenantBrand.from('#F2C200');
    expect(b.on, AppColors.ink);
    expect(hexFromColor(b.ink), '#876C00');
  });

  test('sin color o inválido: petróleo de Workflow, texto blanco', () {
    for (final hex in [null, '', 'verde', '#12345']) {
      final b = TenantBrand.from(hex);
      expect(hexFromColor(b.fill), '#0E6E85');
      expect(b.on, Colors.white);
      expect(hexFromColor(b.ink), '#0E6E85');
    }
  });

  test('ink siempre llega a 4,5:1 contra la piedra', () {
    for (final hex in ['#FFFFFF', '#F2C200', '#54B548', '#D7262E', '#16181A']) {
      final b = TenantBrand.from(hex);
      expect(TenantBrand.contrastRatio(b.ink, AppColors.backgroundLight), greaterThanOrEqualTo(4.5), reason: hex);
    }
  });
}
