import 'package:flutter_test/flutter_test.dart';
import 'package:work_flow/core/auth/profile.dart';
import 'package:work_flow/features/home/home_actions.dart';

Profile profile(List<String> perms, {String? employeeId}) => Profile({
      'permissions': perms,
      'projectPermissions': <String, dynamic>{},
      if (employeeId != null) 'employee': {'id': employeeId},
    });

const field = [
  'remitos.confirm',
  'verifications.submit',
  'inventory.move_within_project',
  'checkins.self',
  'incidents.create',
  'submissions.create',
];

void main() {
  test('empleado de campo: solo acciones del proyecto, sin secciones', () {
    final a = HomeActions.of(profile(field, employeeId: 'e1'), 'p1');
    expect(a.project, [
      HomeAction.scan,
      HomeAction.receiveRemito,
      HomeAction.verification,
      HomeAction.dailyLog,
      HomeAction.incident,
      HomeAction.checkIn,
    ]);
    expect(a.logistics, isEmpty);
    expect(a.showSections, isFalse);
  });

  test('admin con acciones de los dos lados: dos secciones', () {
    final a = HomeActions.of(profile(['*']), 'p1');
    expect(a.logistics, [HomeAction.newItem, HomeAction.returnRemito, HomeAction.requirement]);
    // No es empleado: no marca subida/bajada.
    expect(a.project, isNot(contains(HomeAction.checkIn)));
    expect(a.showSections, isTrue);
  });

  test('permisos por proyecto cuentan solo en ese proyecto', () {
    const p = Profile({
      'permissions': field,
      'projectPermissions': {
        'p1': ['inventory.*'],
      },
    });
    expect(HomeActions.of(p, 'p1').logistics, [HomeAction.newItem]);
    expect(HomeActions.of(p, 'p2').logistics, isEmpty);
  });
}
