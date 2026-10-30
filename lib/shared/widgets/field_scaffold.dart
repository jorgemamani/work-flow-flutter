import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_extensions.dart';

/// Pantalla de campo: volver (48 px), título grande, contenido y, si hay,
/// el botón principal fijo abajo. La franja de conexión la pone
/// [ConnectionFrame] arriba de todo.
///
/// Con [children] el encabezado se desplaza con el contenido; con [body] queda
/// fijo arriba con una línea debajo (pantallas con progreso).
class FieldScaffold extends StatelessWidget {
  const FieldScaffold({
    super.key,
    this.title,
    this.titleBadge,
    this.subtitle,
    this.eyebrow,
    this.above,
    this.headerBottom,
    this.topTrailing,
    this.titleTrailing,
    this.children,
    this.body,
    this.footer,
    this.onRefresh,
    this.showBack,
    this.actions = const [],
    this.gap = 20,
  }) : assert((children == null) != (body == null), 'children o body');

  final String? title;

  /// Junto al título (la chapa del remito).
  final Widget? titleBadge;
  final Widget? subtitle;
  final String? eyebrow;

  /// Arriba del título (chapa y estado del ítem).
  final Widget? above;

  /// Debajo del título (progreso).
  final Widget? headerBottom;

  /// En la fila de volver, a la derecha (marca de la empresa).
  final Widget? topTrailing;

  /// En la fila del título, a la derecha.
  final Widget? titleTrailing;
  final List<Widget>? children;
  final Widget? body;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
  final bool? showBack;
  final List<Widget> actions;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? context.canPop();
    final header = _Header(
      canPop: canPop,
      title: title,
      titleBadge: titleBadge,
      subtitle: subtitle,
      eyebrow: eyebrow,
      above: above,
      headerBottom: headerBottom,
      topTrailing: topTrailing,
      titleTrailing: titleTrailing,
      actions: actions,
    );
    Widget content;
    if (children != null) {
      final list = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(AppSizes.md, canPop ? 4 : AppSizes.md, AppSizes.md, AppSizes.lg),
        children: [
          header,
          for (final c in children!) ...[SizedBox(height: gap), c],
        ],
      );
      content = onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(AppSizes.md, canPop ? 4 : AppSizes.md, AppSizes.md, 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: header,
          ),
          Expanded(child: body!),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // Tocar afuera de un campo cierra el teclado (el numérico no tiene
      // "Listo" y tapa el botón de abajo).
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(bottom: footer == null, child: content),
      ),
      bottomNavigationBar: footer,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.canPop,
    required this.title,
    required this.titleBadge,
    required this.subtitle,
    required this.eyebrow,
    required this.above,
    required this.headerBottom,
    required this.topTrailing,
    required this.titleTrailing,
    required this.actions,
  });

  final bool canPop;
  final String? title;
  final Widget? titleBadge;
  final Widget? subtitle;
  final String? eyebrow;
  final Widget? above;
  final Widget? headerBottom;
  final Widget? topTrailing;
  final Widget? titleTrailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final showTop = canPop || topTrailing != null || actions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTop)
          SizedBox(
            height: AppSizes.tapTarget,
            child: Row(
              children: [
                if (canPop)
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: IconButton(
                      tooltip: context.l10n.back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                const Spacer(),
                ...actions,
                if (topTrailing != null) topTrailing!,
              ],
            ),
          ),
        if (title != null)
          Padding(
            padding: EdgeInsets.only(top: showTop ? 4 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (above != null) ...[above!, const SizedBox(height: 10)],
                      if (eyebrow != null) ...[
                        Text(eyebrow!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                      ],
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title!, style: context.textTheme.headlineSmall),
                          if (titleBadge != null) titleBadge!,
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle.merge(
                          style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textSecondary),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (titleTrailing != null) ...[const SizedBox(width: 12), titleTrailing!],
              ],
            ),
          ),
        if (headerBottom != null) ...[const SizedBox(height: 12), headerBottom!],
      ],
    );
  }
}

/// Pie fijo con el botón principal y, debajo, una ayuda corta.
class FieldFooter extends StatelessWidget {
  const FieldFooter({super.key, required this.children, this.hint});

  final List<Widget> children;
  final String? hint;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSizes.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, 12, AppSizes.md, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 8), c],
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
