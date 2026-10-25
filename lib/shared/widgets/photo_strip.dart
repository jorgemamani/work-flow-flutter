import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../constants/app_colors.dart';
import 'dashed_border.dart';
import '../extensions/context_extensions.dart';

/// Fotos de un renglón: miniaturas, borrar y agregar (cámara o galería),
/// respetando el máximo y si la foto es obligatoria.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    required this.onChanged,
    required this.max,
    this.required = false,
    this.showError = false,
    this.tileSize = 88,
  });

  final List<LocalPhoto> photos;
  final VoidCallback onChanged;
  final int max;
  final bool required;
  final bool showError;
  final double tileSize;

  Future<void> _add(BuildContext context) async {
    final l = context.l10n;
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l.photoFromCamera),
              onTap: () => Navigator.pop(c, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.photoFromGallery),
              onTap: () => Navigator.pop(c, false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null) return;
    final photo = await sl<PhotoService>().take(fromCamera: fromCamera);
    if (photo == null) return;
    photos.add(photo);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final missing = required && photos.isEmpty;
    final warn = missing && showError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: tileSize,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(p.path), width: tileSize, height: tileSize, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: l.discard,
                          onPressed: () {
                            photos.remove(p);
                            sl<PhotoService>().discard(p);
                            onChanged();
                          },
                          icon: Container(
                            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (photos.length < max)
                DashedBorder(
                  color: missing ? AppColors.statusWarning : const Color(0xFF8A8D89),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('addPhoto'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _add(context),
                      child: SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_outlined, size: 22, color: AppColors.ink),
                            const SizedBox(height: 4),
                            Text(
                              l.addPhotoShort,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          missing ? l.photoRequired : l.photosCount(photos.length, max),
          style: TextStyle(
            fontSize: 13,
            fontWeight: warn ? FontWeight.w500 : FontWeight.w400,
            color: warn ? AppColors.statusError : (missing ? AppColors.statusWarning : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
