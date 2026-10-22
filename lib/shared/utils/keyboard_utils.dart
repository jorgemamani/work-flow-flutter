import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Oculta el teclado virtual de forma fiable (Android/iOS).
///
/// Combina [unfocus] con la llamada nativa `TextInput.hide`, que es la única
/// forma consistente de cerrar el teclado cuando hay un [TextField] con foco.
Future<void> hideKeyboard([BuildContext? context]) async {
  final primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus != null && primaryFocus.hasFocus) {
    primaryFocus.unfocus();
  }

  if (context != null && context.mounted) {
    FocusScope.of(context).unfocus();
  }

  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

/// Espera a que el teclado termine de cerrarse antes de abrir overlays.
Future<void> prepareForOverlay(BuildContext context) async {
  await hideKeyboard(context);
  if (!context.mounted) return;
  // Breve pausa para que el SO actualice viewInsets antes del modal.
  await Future<void>.delayed(const Duration(milliseconds: 80));
}
