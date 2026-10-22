import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_extensions.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.textDisabled),
              const SizedBox(height: AppSizes.md),
              Text(
                text,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSizes.lg, 0, AppSizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color = AppColors.statusInfo, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
            Text(label, style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// Aviso "se guarda en el teléfono y se envía al tener señal".
class LocalSaveHint extends StatelessWidget {
  const LocalSaveHint({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            const Icon(Icons.offline_bolt_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.l10n.savedLocallyHint,
                style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
}

Color assetStatusColor(String status) => switch (status) {
      'OPERATIONAL' => AppColors.statusSuccess,
      'RESERVED' => AppColors.info,
      'IN_REPAIR' => AppColors.statusWarning,
      'DAMAGED' => AppColors.statusError,
      'LOST' => AppColors.statusError,
      _ => AppColors.textSecondary,
    };

/// Snackbar corto de "guardado; se envía al tener señal".
void showSaved(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.savedQueued)),
  );
}
