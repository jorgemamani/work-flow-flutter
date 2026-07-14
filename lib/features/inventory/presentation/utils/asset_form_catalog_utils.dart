import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/asset_form_bloc.dart';
import '../bloc/asset_form_event.dart';
import '../bloc/asset_form_state.dart';

/// Despacha un evento de catálogo y espera a que el BLoC confirme el cambio
/// o reporte un error, para refrescar el sheet de selección al volver.
Future<void> dispatchAssetFormCatalogEvent(
  BuildContext context, {
  required AssetFormEvent event,
  required bool Function(AssetFormState before, AssetFormState after)
      wasUpdated,
}) async {
  final bloc = context.read<AssetFormBloc>();
  final before = bloc.state;
  final previousError = before.errorMessage;

  bloc.add(event);

  await bloc.stream
      .firstWhere(
        (after) =>
            wasUpdated(before, after) ||
            (after.errorMessage != null &&
                after.errorMessage != previousError),
      )
      .timeout(const Duration(seconds: 20));

  final after = bloc.state;
  if (after.errorMessage != null && after.errorMessage != previousError) {
    throw StateError(after.errorMessage!);
  }
}
