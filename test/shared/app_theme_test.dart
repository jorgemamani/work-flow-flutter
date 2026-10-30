import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_flow/shared/constants/app_colors.dart';
import 'package:work_flow/shared/theme/app_theme.dart';
import 'package:work_flow/shared/theme/tenant_brand.dart';

Future<(Color?, Color?)> _chip(WidgetTester t, TenantBrand brand, {required bool selected}) async {
  await t.pumpWidget(MaterialApp(
    theme: buildAppTheme(brand),
    home: Scaffold(body: ChoiceChip(label: const Text('Bueno'), selected: selected, onSelected: (_) {})),
  ));
  await t.pumpAndSettle();
  final text = DefaultTextStyle.of(t.element(find.text('Bueno'))).style.color;
  final ink = t.widget<Ink>(find.ancestor(of: find.text('Bueno'), matching: find.byType(Ink)));
  return (text, (ink.decoration! as ShapeDecoration).color);
}

void main() {
  for (final hex in ['#54B548', null]) {
    final brand = TenantBrand.from(hex);

    testWidgets('chip sin elegir: texto en tinta sobre blanco ($hex)', (t) async {
      final (text, bg) = await _chip(t, brand, selected: false);
      expect(text, AppColors.ink);
      expect(bg, AppColors.surfaceLight);
    });

    testWidgets('chip elegido: texto `on` sobre el color de la empresa ($hex)', (t) async {
      final (text, bg) = await _chip(t, brand, selected: true);
      expect(bg, brand.fill);
      expect(text, brand.on);
    });

    test('botón principal en el color de la empresa ($hex)', () {
      final style = buildAppTheme(brand).filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve({}), brand.fill);
      expect(style.foregroundColor!.resolve({}), brand.on);
    });
  }
}
