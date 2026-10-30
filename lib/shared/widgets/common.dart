import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../theme/tenant_brand.dart';

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
              Icon(icon, size: 40, color: AppColors.textDisabled),
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

/// Título de sección. [strong]: 18 en tinta ("Para hacer"); si no, 15 gris
/// ("Dónde está").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.strong = false, this.padTop = true});

  final String text;
  final Widget? trailing;
  final bool strong;
  final bool padTop;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(0, padTop ? 20 : 0, 0, AppSizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: strong
                    ? const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)
                    : const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class StatusDot extends StatelessWidget {
  const StatusDot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Estado: punto + texto del mismo color, sin pastilla. El color es el
/// significado (bien, atención, problema, en tránsito, neutro), nunca el de
/// la empresa.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color = AppColors.statusNeutral, this.fontSize = 14});

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      );
}

/// La chapa: el código del ítem o del remito en mono, con borde de tinta.
class Chapa extends StatelessWidget {
  const Chapa(this.code, {super.key, this.fontSize = 15});

  final String code;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: fontSize >= 15 ? 8 : 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
        child: Text(code, style: AppFonts.monoStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: AppColors.ink)),
      );
}

/// Lista con regla de tinta arriba y línea entre filas.
class RuledList extends StatelessWidget {
  const RuledList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.ink))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in children)
              DecoratedBox(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: c,
              ),
          ],
        ),
      );
}

/// Fila de 64: punto o ícono, título, detalle y flecha.
class RowLink extends StatelessWidget {
  const RowLink({
    super.key,
    required this.title,
    this.detail,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = true,
  });

  final String title;
  final Widget? detail;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle.merge(
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          child: detail!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (chevron && onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 22, color: AppColors.textSecondary),
                ],
              ],
            ),
          ),
        ),
      );
}

/// Aviso sobre fondo "elegido", con el ícono del color que corresponda.
class FieldNotice extends StatelessWidget {
  const FieldNotice({
    super.key,
    required this.child,
    this.icon = Icons.info_outline,
    this.iconColor = AppColors.ink,
  });

  final Widget child;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.selected, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink),
                child: child,
              ),
            ),
          ],
        ),
      );
}

/// "3 de 4 revisados" con la barra de tinta.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.label, required this.value, this.trailing});

  final String label;
  final double value;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6),
          ),
        ],
      );
}

class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.hint, this.key});

  final T value;
  final String label;
  final String? hint;
  final Key? key;
}

/// Opciones grandes en grilla (llegó / falta / dañado, tipo de problema):
/// lo elegido en el color de la empresa. Con [allowNone], tocar lo elegido lo desmarca.
class ChoiceGrid<T> extends StatelessWidget {
  const ChoiceGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.columns = 2,
    this.height = 52,
    this.allowNone = false,
    this.semanticLabel,
  });

  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final int columns;
  final double height;
  final bool allowNone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final rows = <List<ChoiceOption<T>>>[
      for (var i = 0; i < options.length; i += columns)
        options.sublist(i, (i + columns).clamp(0, options.length)),
    ];
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Column(
        children: [
          for (final (ri, row) in rows.indexed) ...[
            if (ri > 0) const SizedBox(height: 8),
            // Misma altura en toda la fila aunque un texto ocupe dos líneas.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: i < row.length ? _tile(row[i]) : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(ChoiceOption<T> o) {
    final on = o.value == selected;
    return Builder(builder: (context) => _tileIn(context, o, on));
  }

  Widget _tileIn(BuildContext context, ChoiceOption<T> o, bool on) {
    final brand = context.brand;
    final fg = on ? brand.on : AppColors.ink;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? brand.fill : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: on ? brand.fill : AppColors.lineStrong, width: 1.5),
        ),
        child: InkWell(
          key: o.key,
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(on && allowNone ? null : o.value),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: o.hint == null ? 6 : 14, vertical: 8),
              child: o.hint == null
                  ? Center(
                      child: Text(
                        o.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(o.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
                        const SizedBox(height: 2),
                        Text(o.hint!, style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.8))),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta arriba del campo (no flotante): se lee con guantes y al sol.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.child, this.note});

  final String text;
  final String? note;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: text,
              children: [
                if (note != null)
                  TextSpan(
                    text: ' $note',
                    style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
          if (child != null) ...[const SizedBox(height: 8), child!],
        ],
      );
}

/// Aviso "se guarda en el teléfono y se envía al tener señal".
class LocalSaveHint extends StatelessWidget {
  const LocalSaveHint({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) => Text(
        text ?? context.l10n.savedLocallyHint,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
      );
}

/// Color de cada estado de un ítem (LOG-05). Reservado en tinta; en tránsito
/// es un portador, no un estado: se pinta con [AppColors.statusMove].
Color assetStatusColor(String status) => switch (status) {
      'OPERATIONAL' => AppColors.statusSuccess,
      'RESERVED' => AppColors.ink,
      'IN_REPAIR' => AppColors.statusWarning,
      'DAMAGED' => AppColors.statusError,
      'LOST' => AppColors.statusError,
      _ => AppColors.statusNeutral,
    };

/// Snackbar corto de "guardado; se envía al tener señal".
void showSaved(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.savedQueued)),
  );
}
