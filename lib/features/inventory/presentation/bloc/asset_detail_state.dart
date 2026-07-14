import 'package:equatable/equatable.dart';

import '../../domain/entities/asset.dart';

enum AssetDetailStatus { initial, loading, loaded, failure }

class AssetDetailState extends Equatable {
  const AssetDetailState({
    this.status = AssetDetailStatus.initial,
    this.asset,
    this.errorMessage,
  });

  final AssetDetailStatus status;
  final Asset? asset;
  final String? errorMessage;

  AssetDetailState copyWith({
    AssetDetailStatus? status,
    Asset? asset,
    String? Function()? errorMessage,
  }) {
    return AssetDetailState(
      status: status ?? this.status,
      asset: asset ?? this.asset,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, asset, errorMessage];
}
