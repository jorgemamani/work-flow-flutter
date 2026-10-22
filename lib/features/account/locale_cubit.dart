import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/db/record_store.dart';

/// Idioma elegido en la app (null = el del teléfono).
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._store) : super(null);

  final RecordStore _store;

  Future<void> load() async {
    final code = await _store.getValue(KvKeys.locale);
    if (code != null) emit(Locale(code));
  }

  Future<void> set(String? code) async {
    await _store.setValue(KvKeys.locale, code);
    emit(code == null ? null : Locale(code));
  }
}
