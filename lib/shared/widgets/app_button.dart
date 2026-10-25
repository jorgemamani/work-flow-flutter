import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import 'app_loading.dart';

/// Botón de campo (56 px, radio 14). Lleno = la acción principal, en tinta;
/// [isOutlined] = secundaria, con borde de tinta. Una sola acción principal
/// por pantalla.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.subtitle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final double? width;
  final double height;

  /// Segunda línea en mono ("ahora · 07:42").
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fg = isOutlined ? AppColors.ink : Colors.white;
    final Widget content;
    if (isLoading) {
      content = AppLoading(color: isOutlined ? AppColors.ink : Colors.white);
    } else {
      final text = subtitle == null
          ? Text(label)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: onPressed == null ? AppColors.textSecondary : fg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            );
      content = icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [icon!, const SizedBox(width: 10), Flexible(child: text)],
            );
    }
    final size = Size(width ?? double.infinity, height);
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(minimumSize: size),
              child: content,
            )
          : FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                minimumSize: size,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(height > AppSizes.buttonHeight ? AppSizes.radiusLg : AppSizes.radiusMd),
                ),
              ),
              child: content,
            ),
    );
  }
}
