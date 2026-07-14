/// Tipos MIME aceptados por `POST /inventory/assets/{id}/images/presign`.
const kAllowedImageContentTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
};

/// Normaliza el MIME de una imagen al formato que espera la API.
String resolveImageContentType({
  String? mimeType,
  required String path,
}) {
  var normalized = mimeType?.toLowerCase().trim();
  if (normalized == 'image/jpg') normalized = 'image/jpeg';

  if (normalized != null && kAllowedImageContentTypes.contains(normalized)) {
    return normalized;
  }

  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/jpeg',
  };
}

String fileExtensionForContentType(String contentType) {
  return switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/heic' => 'heic',
    _ => 'jpg',
  };
}
