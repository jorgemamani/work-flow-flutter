import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_asset_usecase.dart';
import '../../domain/usecases/get_assets_usecase.dart';
import '../../domain/usecases/get_conditions_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({
    required GetAssetsUseCase getAssetsUseCase,
    required DeleteAssetUseCase deleteAssetUseCase,
    required GetConditionsUseCase getConditionsUseCase,
  })  : _getAssets = getAssetsUseCase,
        _deleteAsset = deleteAssetUseCase,
        _getConditions = getConditionsUseCase,
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
  final GetConditionsUseCase _getConditions;

  Future<void> _onLoad(
    InventoryLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(status: InventoryStatus.loading));
    await _loadConditions(emit);
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
    emit(state.copyWith(conditionFilterId: () => event.conditionId));
    await _fetchAssets(emit);
  }

  Future<void> _onFiltersCleared(
    InventoryFiltersCleared event,
    Emitter<InventoryState> emit,
  ) async {
    emit(state.copyWith(
      query: '',
      typeFilter: () => null,
      conditionFilterId: () => null,
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

  Future<void> _loadConditions(Emitter<InventoryState> emit) async {
    try {
      final conditions = await _getConditions();
      conditions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(state.copyWith(conditions: conditions));
    } catch (_) {
      // El filtro por condición queda vacío si falla la carga.
    }
  }

  Future<void> _fetchAssets(Emitter<InventoryState> emit) async {
    try {
      final assets = await _getAssets(
        query: state.query.isEmpty ? null : state.query,
        type: state.typeFilter,
        conditionId: state.conditionFilterId,
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
