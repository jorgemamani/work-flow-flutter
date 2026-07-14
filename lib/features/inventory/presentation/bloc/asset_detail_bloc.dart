import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/usecases/get_asset_by_id_usecase.dart';
import '../../domain/usecases/get_asset_images_usecase.dart';
import 'asset_detail_event.dart';
import 'asset_detail_state.dart';

class AssetDetailBloc extends Bloc<AssetDetailEvent, AssetDetailState> {
  AssetDetailBloc({
    required GetAssetByIdUseCase getAssetByIdUseCase,
    required GetAssetImagesUseCase getAssetImagesUseCase,
  })  : _getAssetById = getAssetByIdUseCase,
        _getImages = getAssetImagesUseCase,
        super(const AssetDetailState()) {
    on<AssetDetailLoadRequested>(_onLoadRequested);
  }

  final GetAssetByIdUseCase _getAssetById;
  final GetAssetImagesUseCase _getImages;

  Future<void> _onLoadRequested(
    AssetDetailLoadRequested event,
    Emitter<AssetDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: AssetDetailStatus.loading,
      asset: event.preview,
    ));

    try {
      final fetched = await _getAssetById(event.preview.id);

      List<AssetImage> images = [];
      try {
        images = await _getImages(event.preview.id);
      } catch (_) {
        // Si falla solo la carga de fotos, mostramos el resto del detalle.
      }

      final base = fetched ?? event.preview;
      final enriched = _withImages(base, images);

      emit(state.copyWith(
        status: AssetDetailStatus.loaded,
        asset: enriched,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetDetailStatus.failure,
        errorMessage: () => e.toString(),
      ));
    }
  }

  Asset _withImages(Asset asset, List<AssetImage> images) {
    return asset.copyWith(
      images: images,
      photoPaths: images.map((img) => img.url).toList(),
    );
  }
}
