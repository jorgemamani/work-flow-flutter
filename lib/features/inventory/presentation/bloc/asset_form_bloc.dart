import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/usecases/create_asset_usecase.dart';
import '../../domain/usecases/create_brand_usecase.dart';
import '../../domain/usecases/create_model_usecase.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_models_usecase.dart';
import '../../domain/usecases/update_asset_usecase.dart';
import 'asset_form_event.dart';
import 'asset_form_state.dart';

class AssetFormBloc extends Bloc<AssetFormEvent, AssetFormState> {
  AssetFormBloc({
    required GetBrandsUseCase getBrandsUseCase,
    required CreateBrandUseCase createBrandUseCase,
    required GetModelsUseCase getModelsUseCase,
    required CreateModelUseCase createModelUseCase,
    required CreateAssetUseCase createAssetUseCase,
    required UpdateAssetUseCase updateAssetUseCase,
  })  : _getBrands = getBrandsUseCase,
        _createBrand = createBrandUseCase,
        _getModels = getModelsUseCase,
        _createModel = createModelUseCase,
        _createAsset = createAssetUseCase,
        _updateAsset = updateAssetUseCase,
        super(const AssetFormState()) {
    on<AssetFormInitialized>(_onInitialized);
    on<AssetFormTypeChanged>(_onTypeChanged);
    on<AssetFormBrandSelected>(_onBrandSelected);
    on<AssetFormModelSelected>(_onModelSelected);
    on<AssetFormBrandCreated>(_onBrandCreated);
    on<AssetFormModelCreated>(_onModelCreated);
    on<AssetFormPhotoAdded>(_onPhotoAdded);
    on<AssetFormPhotoRemoved>(_onPhotoRemoved);
    on<AssetFormSubItemAdded>(_onSubItemAdded);
    on<AssetFormSubItemUpdated>(_onSubItemUpdated);
    on<AssetFormSubItemRemoved>(_onSubItemRemoved);
    on<AssetFormConditionChanged>(_onConditionChanged);
    on<AssetFormSubmitted>(_onSubmitted);
  }

  final GetBrandsUseCase _getBrands;
  final CreateBrandUseCase _createBrand;
  final GetModelsUseCase _getModels;
  final CreateModelUseCase _createModel;
  final CreateAssetUseCase _createAsset;
  final UpdateAssetUseCase _updateAsset;

  Future<void> _onInitialized(
    AssetFormInitialized event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(status: AssetFormStatus.loading));
    try {
      final brands = await _getBrands();
      final type = event.asset?.type ?? AssetType.tool;
      final selectedBrand = event.asset?.brandId != null
          ? brands.where((b) => b.id == event.asset!.brandId).firstOrNull
          : null;

      List<AssetModelEntity> models = const [];
      if (selectedBrand != null) {
        models = await _getModels(selectedBrand.id);
      }

      emit(state.copyWith(
        status: AssetFormStatus.initial,
        selectedType: type,
        brands: brands,
        models: models,
        selectedBrand: () => selectedBrand,
        photoPaths: event.asset?.photoPaths ?? const [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetFormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTypeChanged(
    AssetFormTypeChanged event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(selectedType: event.type));
  }

  Future<void> _onBrandSelected(
    AssetFormBrandSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(
      selectedBrand: () => event.brand,
      selectedModel: () => null,
      models: const [],
    ));
    if (event.brand != null) {
      try {
        final models = await _getModels(event.brand!.id);
        emit(state.copyWith(models: models));
      } catch (_) {}
    }
  }

  Future<void> _onModelSelected(
    AssetFormModelSelected event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(selectedModel: () => event.model));
  }

  Future<void> _onBrandCreated(
    AssetFormBrandCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final brand = await _createBrand(event.name);
      final brands = [...state.brands, brand];
      brands.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        brands: brands,
        selectedBrand: () => brand,
        selectedModel: () => null,
        models: const [],
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onModelCreated(
    AssetFormModelCreated event,
    Emitter<AssetFormState> emit,
  ) async {
    try {
      final model = await _createModel(
        brandId: event.brandId,
        name: event.name,
      );
      final models = [...state.models, model];
      models.sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        models: models,
        selectedModel: () => model,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onPhotoAdded(
    AssetFormPhotoAdded event,
    Emitter<AssetFormState> emit,
  ) {
    emit(state.copyWith(photoPaths: [...state.photoPaths, event.path]));
  }

  void _onPhotoRemoved(
    AssetFormPhotoRemoved event,
    Emitter<AssetFormState> emit,
  ) {
    final updated = List<String>.from(state.photoPaths)
      ..removeAt(event.index);
    emit(state.copyWith(photoPaths: updated));
  }

  void _onSubItemAdded(
    AssetFormSubItemAdded event,
    Emitter<AssetFormState> emit,
  ) {
    // Sub-items are managed via form state in the page; BLoC only needs
    // photoPaths and catalogs. Kept here for completeness.
  }

  void _onSubItemUpdated(
    AssetFormSubItemUpdated event,
    Emitter<AssetFormState> emit,
  ) {}

  void _onSubItemRemoved(
    AssetFormSubItemRemoved event,
    Emitter<AssetFormState> emit,
  ) {}

  void _onConditionChanged(
    AssetFormConditionChanged event,
    Emitter<AssetFormState> emit,
  ) {}

  Future<void> _onSubmitted(
    AssetFormSubmitted event,
    Emitter<AssetFormState> emit,
  ) async {
    emit(state.copyWith(status: AssetFormStatus.loading));
    try {
      final Asset saved;
      if (event.asset.id.isEmpty) {
        saved = await _createAsset(event.asset);
      } else {
        saved = await _updateAsset(event.asset);
      }
      emit(state.copyWith(
        status: AssetFormStatus.success,
        savedAsset: saved,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetFormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
