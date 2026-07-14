import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/bottom_sheet_utils.dart';
import '../../../../shared/utils/image_content_type_utils.dart';
import '../../../../shared/widgets/app_image.dart';
import '../bloc/asset_form_state.dart';

typedef PhotoAddedCallback = void Function(String path, String contentType);

class PhotoPickerWidget extends StatelessWidget {
  const PhotoPickerWidget({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<AssetPhotoEntry> photos;
  final PhotoAddedCallback onAdd;
  final ValueChanged<int> onRemove;

  bool get _canAdd => photos.length < AppConstants.maxPhotosPerAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Fotos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              '(${photos.length}/${AppConstants.maxPhotosPerAsset})',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_canAdd)
                _AddPhotoButton(
                  onCamera: () => _pick(context, ImageSource.camera),
                  onGallery: () => _pick(context, ImageSource.gallery),
                ),
              for (var i = 0; i < photos.length; i++)
                _PhotoTile(
                  entry: photos[i],
                  onRemove: () => onRemove(i),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (!_canAdd) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (xFile == null) return;

    try {
      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) return;

      final contentType = resolveImageContentType(
        mimeType: xFile.mimeType,
        path: xFile.path,
      );
      final ext = fileExtensionForContentType(contentType);
      final persisted = File(
        '${Directory.systemTemp.path}/wf_asset_'
        '${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await persisted.writeAsBytes(bytes, flush: true);

      onAdd(persisted.path, contentType);
    } catch (_) {
      // Si falla la copia local, intentar con el path original del picker.
      final contentType = resolveImageContentType(
        mimeType: xFile.mimeType,
        path: xFile.path,
      );
      onAdd(xFile.path, contentType);
    }
  }
}

// ── Add button ────────────────────────────────────────────────────────────────

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: GestureDetector(
        onTap: () => _showOptions(context),
        child: Container(
          width: 80,
          height: 88,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                'Añadir',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Agregar foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded),
                    title: const Text('Tomar foto'),
                    onTap: () {
                      Navigator.pop(context);
                      onCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded),
                    title: const Text('Elegir de galería'),
                    onTap: () {
                      Navigator.pop(context);
                      onGallery();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}

// ── Photo tile ────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.entry, required this.onRemove});

  final AssetPhotoEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: Stack(
        children: [
          // ── Imagen (local o remota, resuelta por AppImage) ──────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: AppImage(
              path: entry.displayUrl,
              width: 80,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),

          // ── Overlay de estado ────────────────────────────────────────────
          if (entry.isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (entry.hasError)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
              ),
            ),

          // ── Botón de eliminar (no mostrar mientras sube) ─────────────────
          if (!entry.isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
