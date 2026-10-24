import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/field_repository.dart';
import '../../dependency_injection.dart';

/// Lee de la base local y vuelve a leer cuando una sync o un hecho encolado
/// cambia alguna de las [sources] (vacío = cualquier cambio).
class LiveQuery<T> extends StatefulWidget {
  const LiveQuery({
    super.key,
    required this.query,
    required this.builder,
    this.sources = const {},
    this.deps = const [],
  });

  final Future<T> Function() query;
  final Widget Function(BuildContext context, T data) builder;
  final Set<String> sources;

  /// Si cambian (ej. el proyecto actual), se vuelve a consultar.
  final List<Object?> deps;

  @override
  State<LiveQuery<T>> createState() => _LiveQueryState<T>();
}

class _LiveQueryState<T> extends State<LiveQuery<T>> {
  late Future<T> _future;
  T? _last;
  StreamSubscription<Set<String>>? _sub;

  @override
  void initState() {
    super.initState();
    _future = _run();
    _sub = sl<FieldRepository>().changes.listen((changed) {
      if (widget.sources.isEmpty || changed.any(widget.sources.contains)) {
        setState(() {
          _future = _run();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveQuery<T> old) {
    super.didUpdateWidget(old);
    if (!_sameDeps(old.deps, widget.deps)) _future = _run();
  }

  static bool _sameDeps(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<T> _run() async {
    final v = await widget.query();
    _last = v;
    return v;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final data = snap.data ?? _last;
          if (data == null) return const Center(child: CircularProgressIndicator());
          return widget.builder(context, data as T);
        },
      );
}
