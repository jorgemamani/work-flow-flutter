import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/http_client/domain/http_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_image.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_type.dart';
import '../../domain/entities/condition_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/warehouse_entity.dart';
import '../models/asset_image_model.dart';

abstract class IAssetRemoteDataSource {
  // ── Assets ────────────────────────────────────────────────────────────────
  Future<List<Asset>> getAssets({String? category, String? status});
  Future<Asset> getAssetById(String id);
  Future<Asset> createAsset(Map<String, dynamic> body);
  Future<Asset> updateAsset(String id, Map<String, dynamic> body);
  Future<void> deleteAsset(String id);

  // ── Brands ────────────────────────────────────────────────────────────────
  Future<List<AssetBrand>> getBrands();
  Future<AssetBrand> createBrand(String name);

  // ── Projects ──────────────────────────────────────────────────────────────
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity> createProject(String name);

  // ── Warehouses ────────────────────────────────────────────────────────────
  Future<List<WarehouseEntity>> getWarehouses();
  Future<WarehouseEntity> createWarehouse({
    required String name,
    required String type,
    String? projectId,
  });

  // ── Models ────────────────────────────────────────────────────────────────
  Future<List<AssetModelEntity>> getModels({String? brandId});
  Future<AssetModelEntity> createModel({
    required String name,
    required String category,
    String? brandId,
  });

  // ── Conditions ────────────────────────────────────────────────────────────
  Future<List<ConditionEntity>> getConditions();
  Future<ConditionEntity> createCondition({
    required String name,
    required String color,
    int? sortOrder,
  });

  // ── Images (flujo R2) ─────────────────────────────────────────────────────

  /// Paso 1 del flujo de imágenes: obtiene la URL firmada de R2.
  Future<PresignedUploadResult> presignImage({
    required String assetId,
    required String contentType,
  });

  /// Paso 2 (interno): hace el PUT binario directo a la `uploadUrl` de R2.
  /// Lanza [ServerException] si el status code no es 200.
  Future<void> uploadToR2({
    required String uploadUrl,
    required File file,
    required String contentType,
  });

  /// Paso 3: confirma la imagen en la API para persistirla en BD.
  /// SOLO llamar si el PUT a R2 fue exitoso.
  Future<AssetImage> confirmImage({
    required String assetId,
    required String key,
    required String publicUrl,
    int sortOrder = 0,
  });

  Future<List<AssetImage>> getImages(String assetId);
  Future<void> deleteImage({required String assetId, required String imageId});
}

// ─────────────────────────────────────────────────────────────────────────────

class AssetRemoteDataSourceImpl implements IAssetRemoteDataSource {
  AssetRemoteDataSourceImpl(this._httpClient, this._r2Dio);

  final IHttpClient _httpClient;

  /// Instancia de Dio SIN interceptores de auth — para subir a R2 directamente.
  final Dio _r2Dio;

  // ── Assets ────────────────────────────────────────────────────────────────

  @override
  Future<List<Asset>> getAssets({String? category, String? status}) async {
    final queryParams = <String, dynamic>{
      'limit': 100,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    };

    final response = await _httpClient.get(
      ApiEndpoints.assets,
      queryParameters: queryParams,
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => _assetFromApiJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Asset> getAssetById(String id) async {
    final response = await _httpClient.get(
      ApiEndpoints.assetById(id),
    ) as Map<String, dynamic>;

    return _assetFromApiJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Asset> createAsset(Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      ApiEndpoints.assets,
      data: body,
    ) as Map<String, dynamic>;

    return _assetFromApiJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Asset> updateAsset(String id, Map<String, dynamic> body) async {
    final response = await _httpClient.patch(
      ApiEndpoints.assetById(id),
      data: body,
    ) as Map<String, dynamic>;

    return _assetFromApiJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await _httpClient.delete(ApiEndpoints.assetById(id));
  }

  // ── Brands ────────────────────────────────────────────────────────────────

  @override
  Future<List<AssetBrand>> getBrands() async {
    final response = await _httpClient.get(
      ApiEndpoints.brands,
      queryParameters: {'limit': 100},
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return AssetBrand(id: map['id'] as String, name: map['name'] as String);
    }).toList();
  }

  @override
  Future<AssetBrand> createBrand(String name) async {
    final response = await _httpClient.post(
      ApiEndpoints.brands,
      data: {'name': name},
    ) as Map<String, dynamic>;

    final data = response['data'] as Map<String, dynamic>;
    return AssetBrand(id: data['id'] as String, name: data['name'] as String);
  }

  // ── Models ────────────────────────────────────────────────────────────────

  @override
  Future<List<AssetModelEntity>> getModels({String? brandId}) async {
    final response = await _httpClient.get(
      ApiEndpoints.models,
      queryParameters: {
        'limit': 100,
        if (brandId != null) 'brandId': brandId,
      },
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data.map((e) => _modelFromApiJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AssetModelEntity> createModel({
    required String name,
    required String category,
    String? brandId,
  }) async {
    final response = await _httpClient.post(
      ApiEndpoints.models,
      data: {
        'name': name,
        'category': category,
        if (brandId != null) 'brandId': brandId,
      },
    ) as Map<String, dynamic>;

    return _modelFromApiJson(response['data'] as Map<String, dynamic>);
  }

  // ── Conditions ────────────────────────────────────────────────────────────

  @override
  Future<List<ConditionEntity>> getConditions() async {
    final response = await _httpClient.get(
      ApiEndpoints.conditions,
      queryParameters: {'limit': 100},
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => _conditionFromJson(e as Map<String, dynamic>))
        .where((c) => c.isActive)
        .toList();
  }

  @override
  Future<ConditionEntity> createCondition({
    required String name,
    required String color,
    int? sortOrder,
  }) async {
    final response = await _httpClient.post(
      ApiEndpoints.conditions,
      data: {
        'name': name,
        'color': color,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    ) as Map<String, dynamic>;

    return _conditionFromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Images ────────────────────────────────────────────────────────────────

  @override
  Future<PresignedUploadResult> presignImage({
    required String assetId,
    required String contentType,
  }) async {
    final response = await _httpClient.post(
      ApiEndpoints.assetImagesPresign(assetId),
      data: {'contentType': contentType},
    ) as Map<String, dynamic>;

    return PresignedUploadResult.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> uploadToR2({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    if (!await file.exists()) {
      throw const ServerException(
        message: 'No se encontró el archivo de imagen en el dispositivo.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ServerException(message: 'El archivo de imagen está vacío.');
    }

    try {
      await _r2Dio.put<void>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {Headers.contentTypeHeader: contentType},
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString();
      final detail = body != null && body.isNotEmpty ? ': $body' : '';
      throw ServerException(
        message: status != null
            ? 'Error al subir imagen a R2 (HTTP $status)$detail'
            : 'Error de red al subir imagen: ${e.message}',
        statusCode: status,
      );
    }
  }

  @override
  Future<AssetImage> confirmImage({
    required String assetId,
    required String key,
    required String publicUrl,
    int sortOrder = 0,
  }) async {
    final response = await _httpClient.post(
      ApiEndpoints.assetImagesConfirm(assetId),
      data: {'key': key, 'url': publicUrl, 'sortOrder': sortOrder},
    ) as Map<String, dynamic>;

    return AssetImageModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<AssetImage>> getImages(String assetId) async {
    final response = await _httpClient.get(
      ApiEndpoints.assetImages(assetId),
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => AssetImageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteImage({
    required String assetId,
    required String imageId,
  }) async {
    await _httpClient.delete(ApiEndpoints.assetImageById(assetId, imageId));
  }

  // ── Projects ─────────────────────────────────────────────────────────────

  @override
  Future<List<ProjectEntity>> getProjects() async {
    final response = await _httpClient.get(
      ApiEndpoints.projects,
      queryParameters: {'limit': 100, 'status': 'ACTIVE'},
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => _projectFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProjectEntity> createProject(String name) async {
    final response = await _httpClient.post(
      ApiEndpoints.projects,
      data: {'name': name},
    ) as Map<String, dynamic>;

    return _projectFromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Warehouses ───────────────────────────────────────────────────────────

  @override
  Future<List<WarehouseEntity>> getWarehouses() async {
    final response = await _httpClient.get(
      ApiEndpoints.warehouses,
      queryParameters: {'limit': 100},
    ) as Map<String, dynamic>;

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => _warehouseFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WarehouseEntity> createWarehouse({
    required String name,
    required String type,
    String? projectId,
  }) async {
    final response = await _httpClient.post(
      ApiEndpoints.warehouses,
      data: {
        'name': name,
        'type': type,
        if (projectId != null) 'projectId': projectId,
      },
    ) as Map<String, dynamic>;

    return _warehouseFromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Helpers de mapeo ──────────────────────────────────────────────────────

  Asset _assetFromApiJson(Map<String, dynamic> json) {
    final model = json['model'] as Map<String, dynamic>?;
    final brand = model?['brand'] as Map<String, dynamic>?;
    final category = model?['category'] as String?;
    final warehouse = json['currentWarehouse'] as Map<String, dynamic>?;
    final project = json['currentProject'] as Map<String, dynamic>?;
    final condition = json['condition'] as Map<String, dynamic>?;

    final images = (json['images'] as List<dynamic>?)
            ?.map((e) => AssetImageModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <AssetImageModel>[];

    return Asset(
      id: json['id'] as String,
      type: _categoryToType(category),
      description: json['description'] as String? ??
          model?['name'] as String? ??
          json['internalCode'] as String? ??
          '',
      internalCode: json['internalCode'] as String?,
      brandId: brand?['id'] as String?,
      brandName: brand?['name'] as String?,
      modelId: json['modelId'] as String?,
      modelName: model?['name'] as String?,
      serialNumber: json['serialNumber'] as String?,
      color: json['color'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      location: warehouse?['name'] as String? ?? project?['name'] as String?,
      currentProjectId: json['currentProjectId'] as String?,
      currentProjectName: project?['name'] as String?,
      currentWarehouseId: json['currentWarehouseId'] as String?,
      currentWarehouseName: warehouse?['name'] as String?,
      conditionId: json['conditionId'] as String? ?? condition?['id'] as String?,
      conditionName: condition?['name'] as String?,
      conditionColor: condition?['color'] as String?,
      observations: json['notes'] as String?,
      photoPaths: images.map((img) => img.url).toList(),
      images: images,
      // Vehículo
      licensePlate: json['licensePlate'] as String?,
      year: (json['year'] as num?)?.toInt(),
      engineNumber: json['engineNumber'] as String?,
      mileage: (json['currentKm'] as num?)?.toInt(),
      vtvExpiry: _parseDate(json['vtvExpiresAt']),
      insuranceExpiry: _parseDate(json['insuranceExpiresAt']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  ProjectEntity _projectFromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      clientCompany: json['clientCompany'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  WarehouseEntity _warehouseFromJson(Map<String, dynamic> json) {
    return WarehouseEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'CENTRAL',
      projectId: json['projectId'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  ConditionEntity _conditionFromJson(Map<String, dynamic> json) {
    return ConditionEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#607D8B',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AssetModelEntity _modelFromApiJson(Map<String, dynamic> json) {
    final brandMap = json['brand'] as Map<String, dynamic>?;
    return AssetModelEntity(
      id: json['id'] as String,
      brandId: json['brandId'] as String? ?? brandMap?['id'] as String? ?? '',
      name: json['name'] as String,
      category: json['category'] as String? ?? 'TOOL',
    );
  }

  static AssetType _categoryToType(String? category) => switch (category) {
        'VEHICLE' => AssetType.vehicle,
        'TOOL' => AssetType.tool,
        'TOOLBOX' => AssetType.toolBox,
        'EPP' => AssetType.epp,
        'CABLE_ACCESSORY' => AssetType.cable,
        'CONSUMABLE' => AssetType.consumable,
        _ => AssetType.tool,
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }
}
