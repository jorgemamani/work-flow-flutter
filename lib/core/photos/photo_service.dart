import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors/app_exception.dart';
import '../ids.dart';
import '../network/api_client.dart';
import '../network/api_paths.dart';
import '../outbox/outbox_processor.dart';

/// Foto sacada en el teléfono, comprimida y guardada hasta que se suba.
class LocalPhoto {
  const LocalPhoto({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.takenAt,
  });

  /// Id del adjunto (UUIDv7): se declara en el hecho antes de subir la foto.
  final String id;
  final String path;
  final int sizeBytes;
  final DateTime takenAt;

  static const mimeType = 'image/jpeg';
}

/// Saca, comprime y guarda fotos (v4 §11: se comprimen en el teléfono).
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxSide = 1600;
  static const quality = 70;

  Future<Directory> _dir(String name) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, name));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Devuelve null si el usuario canceló.
  Future<LocalPhoto?> take({required bool fromCamera}) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        requestFullMetadata: false,
      );
    } catch (_) {
      // Sin cámara (simulador): caer a la galería.
      if (!fromCamera) rethrow;
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    }
    if (picked == null) return null;
    final id = newId();
    final out = p.join((await _dir('photos')).path, '$id.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      out,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    final file = result == null ? await File(picked.path).copy(out) : File(result.path);
    return LocalPhoto(
      id: id,
      path: file.path,
      sizeBytes: await file.length(),
      takenAt: DateTime.now(),
    );
  }

  Future<void> discard(LocalPhoto photo) async {
    final f = File(photo.path);
    if (await f.exists()) await f.delete();
  }

  // ── Fotos vigentes (RN-22) para ver sin señal ──────────────────────────────

  Future<File> _cacheFile(String attachmentId) async =>
      File(p.join((await _dir('photo_cache')).path, '$attachmentId.jpg'));

  /// Una foto sacada en el teléfono que va a ser la vigente: se copia al
  /// caché para verla ya, sin esperar a subirla y bajarla.
  Future<void> cacheAsCurrent(LocalPhoto photo) async {
    final src = File(photo.path);
    if (await src.exists()) await src.copy((await _cacheFile(photo.id)).path);
  }

  Future<File?> cached(String attachmentId) async {
    final f = await _cacheFile(attachmentId);
    return await f.exists() ? f : null;
  }

  /// Baja la foto si no está; null si no hay señal o todavía no se subió.
  Future<File?> ensure(ApiClient api, String attachmentId) async {
    final hit = await cached(attachmentId);
    if (hit != null) return hit;
    try {
      final data = await api.get(ApiPaths.attachment(attachmentId)) as Map;
      final url = data['readUrl'] as String?;
      if (url == null) return null;
      final f = await _cacheFile(attachmentId);
      await api.download(url, f.path);
      return f;
    } on OfflineException {
      return null;
    } on ApiException {
      return null;
    }
  }

  /// Descarga previa (v4 §11): las fotos vigentes del proyecto.
  Future<int> prefetch(ApiClient api, Iterable<String> attachmentIds) async {
    var n = 0;
    for (final id in attachmentIds) {
      if (await cached(id) != null) continue;
      if (await ensure(api, id) != null) n++;
    }
    return n;
  }
}
