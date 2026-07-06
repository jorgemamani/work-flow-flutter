import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_asset_usecase.dart';
import '../../domain/usecases/get_assets_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({
    required GetAssetsUseCase getAssetsUseCase,
    required DeleteAssetUseCase deleteAssetUseCase,
  })  : _getAssets = getAssetsUseCase,
        _deleteAsset = deleteAssetUseCase,
        super(const InventoryState()) {
    on<InventoryLoadRequested>(_onLoad);
    on<InventorySearchChanged>(_onSearchChanged);
    on<InventoryTypeFilterChanged>(_onTypeFilterChanged);
    on<InventoryConditionFilterChanged>(_onConditionFilterChanged);
    on<InventoryFiltersCleared>(_onFiltersCleared);
    on<InventoryAssetDeleted>(_onAssetDeleted);
  }

  final GetAssetsUseCase _getAssets;
  final DeleteAssetUseCase _deleteAsset;

  Future<void> _onLoad(
    InventoryLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(status: InventoryStatus.loading));
    await _fetchAssets(emit);
  }

  Future<void> _onSearchChanged(
    InventorySearchChanged event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    await _fetchAssets(emit);
  }

  Future<void> _onTypeFilterChanged(
    InventoryTypeFilterChanged event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(typeFilter: () => event.type));
    await _fetchAssets(emit);
  }

  Future<void> _onConditionFilterChanged(
    InventoryConditionFilterChanged event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(conditionFilter: () => event.condition));
    await _fetchAssets(emit);
  }

  Future<void> _onFiltersCleared(
    InventoryFiltersCleared event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(
      query: '',
      typeFilter: () => null,
      conditionFilter: () => null,
    ));
    await _fetchAssets(emit);
  }

  Future<void> _onAssetDeleted(
    InventoryAssetDeleted event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _deleteAsset(event.assetId);
      await _fetchAssets(emit);
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _fetchAssets(Emitter<InventoryState> emit) async {
    try {
      final assets = await _getAssets(
        query: state.query.isEmpty ? null : state.query,
        type: state.typeFilter,
        condition: state.conditionFilter,
      );
      emit(state.copyWith(
        status: InventoryStatus.success,
        assets: assets,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
