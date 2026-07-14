import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';

abstract class AssetDetailEvent extends Equatable {
  const AssetDetailEvent();

  @override
  List<Object?> get props => [];
}

class AssetDetailLoadRequested extends AssetDetailEvent {
  const AssetDetailLoadRequested(this.preview);

  /// Activo parcial proveniente de la lista (puede no incluir fotos).
  final Asset preview;

  @override
  List<Object?> get props => [preview];
}
