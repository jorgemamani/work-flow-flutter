import 'dart:io';

import '../entities/asset_image.dart';
import '../repositories/asset_repository.dart';

class UploadAssetImageUseCase {
  UploadAssetImageUseCase(this._repository);

  final IAssetRepository _repository;

  Future<AssetImage> call({
    required String assetId,
    required File file,
    required String contentType,
    int sortOrder = 0,
  }) {
    return _repository.uploadImage(
      assetId: assetId,
      file: file,
      contentType: contentType,
      sortOrder: sortOrder,
    );
  }
}
