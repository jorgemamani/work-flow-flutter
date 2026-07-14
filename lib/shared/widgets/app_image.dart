import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Widget centralizado para mostrar imágenes en toda la app.
///
/// Resuelve automáticamente la fuente según el `path`:
/// - `http(s)://...` → red con caché ([CachedNetworkImage])
/// - `assets/...`    → bundle de la app
/// - cualquier otro  → archivo local del dispositivo (ej: foto de image_picker)
///
/// Muestra un placeholder animado durante la carga de imágenes remotas
/// y un widget de error unificado si la imagen no puede cargarse.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Widget a mostrar si la imagen falla. Si es null se usa el default.
  final Widget? errorWidget;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  bool get _isAsset => path.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _Placeholder(width: width, height: height),
        errorWidget: (_, __, ___) => _error(),
      );
    }

    if (_isAsset) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _error(),
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _error(),
    );
  }

  Widget _error() =>
      errorWidget ?? _DefaultError(width: width, height: height);
}

// ── Placeholder animado (efecto pulso, sin dependencias extra) ───────────────

class _Placeholder extends StatefulWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.4,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.border,
      ),
    );
  }
}

// ── Error default ─────────────────────────────────────────────────────────────

class _DefaultError extends StatelessWidget {
  const _DefaultError({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.border,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}
