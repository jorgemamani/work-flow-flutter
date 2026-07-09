import 'package:equatable/equatable.dart';

/// Imagen persistida de un activo (ya confirmada en el backend y almacenada en R2).
class AssetImage extends Equatable {
  const AssetImage({
    required this.id,
    required this.assetId,
    required this.url,
    required this.objectKey,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String assetId;

  /// URL pública en Cloudflare R2.
  final String url;

  /// Clave del objeto en R2 (para borrado o re-confirmación).
  final String objectKey;

  final int sortOrder;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, assetId, url, objectKey, sortOrder, createdAt];
}
