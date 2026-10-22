import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../constants/app_colors.dart';
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
  });

  final List<LocalPhoto> photos;
  final VoidCallback onChanged;
  final int max;
  final bool required;
  final bool showError;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(p.path), width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            photos.remove(p);
                            sl<PhotoService>().discard(p);
                            onChanged();
                          },
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (photos.length < max)
                OutlinedButton(
                  key: const Key('addPhoto'),
                  style: OutlinedButton.styleFrom(
                    fixedSize: const Size(72, 72),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: missing && showError ? AppColors.statusError : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _add(context),
                  child: const Icon(Icons.add_a_photo_outlined),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          missing
              ? l.photoRequired
              : l.photosCount(photos.length, max),
          style: context.textTheme.bodySmall?.copyWith(
            color: missing && showError ? AppColors.statusError : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
