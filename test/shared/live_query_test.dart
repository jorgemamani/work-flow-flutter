import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_flow/core/data/field_repository.dart';
import 'package:work_flow/core/db/local_database.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/dependency_injection.dart';
import 'package:work_flow/shared/widgets/live_query.dart';

import '../helpers/db.dart';

void main() {
  late LocalDatabase local;
  late RecordStore records;

  setUp(() async {
    final (l, r, _) = await openTestDb();
    local = l;
    records = r;
    sl.registerSingleton<FieldRepository>(FieldRepository(records));
  });

  tearDown(() async {
    await sl.reset();
    await local.close();
  });

  // Regresión: la pantalla de inicio quedaba con datos viejos después de la
  // primera sync porque el setState del listener devolvía un Future.
  testWidgets('vuelve a consultar cuando una sync cambia una fuente', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        home: LiveQuery<int>(
          sources: const {'projects'},
          query: () => records.count('projects'),
          builder: (_, n) => Text('proyectos: $n'),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('proyectos: 0'), findsOneWidget);

      await records.transaction((txn) => records.upsertAll(txn, 'projects', [
            {'id': 'p1', 'name': 'Mina'},
          ]));
      records.notify({'projects'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    });
    await tester.pump();
    expect(find.text('proyectos: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
