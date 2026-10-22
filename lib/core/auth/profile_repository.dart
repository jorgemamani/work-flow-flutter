import 'dart:async';

import '../db/record_store.dart';
import '../network/api_client.dart';
import '../network/api_paths.dart';
import 'profile.dart';

/// Perfil del usuario: se baja con señal y se guarda para abrir sin ella.
class ProfileRepository {
  ProfileRepository(this._store, this._api);

  final RecordStore _store;
  final ApiClient _api;
  final _controller = StreamController<Profile?>.broadcast();
  Profile? _current;

  Profile? get current => _current;
  Stream<Profile?> get changes => _controller.stream;

  Future<Profile?> loadCached() async {
    final raw = await _store.getJson(KvKeys.profile);
    _current = raw == null ? null : Profile(raw);
    return _current;
  }

  Future<Profile> fetch() async {
    final data = await _api.get(ApiPaths.me) as Map<String, dynamic>;
    final p = Profile(data);
    await save(p);
    return p;
  }

  Future<void> save(Profile? p) async {
    await _store.setJson(KvKeys.profile, p?.raw);
    _current = p;
    _controller.add(p);
  }
}
