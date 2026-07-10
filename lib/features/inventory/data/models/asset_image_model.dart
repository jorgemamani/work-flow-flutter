import '../../domain/entities/asset_image.dart';

class AssetImageModel extends AssetImage {
  const AssetImageModel({
    required super.id,
    required super.assetId,
    required super.url,
    required super.objectKey,
    required super.sortOrder,
    required super.createdAt,
  });

  factory AssetImageModel.fromJson(Map<String, dynamic> json) {
    return AssetImageModel(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      url: json['url'] as String,
      objectKey: json['objectKey'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Respuesta del endpoint `/presign`.
class PresignedUploadResult {
  const PresignedUploadResult({
    required this.key,
    required this.uploadUrl,
    required this.publicUrl,
  });

  final String key;

  /// URL firmada para hacer el PUT directo a Cloudflare R2.
  final String uploadUrl;

  /// URL pública esperada tras la subida exitosa.
  final String publicUrl;

  factory PresignedUploadResult.fromJson(Map<String, dynamic> json) {
    return PresignedUploadResult(
      key: json['key'] as String,
      uploadUrl: json['uploadUrl'] as String,
      publicUrl: json['publicUrl'] as String,
    );
  }
}
