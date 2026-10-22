import 'package:flutter/material.dart';

import 'keyboard_utils.dart';

/// Muestra un bottom sheet ocultando primero el teclado del formulario padre.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
  ShapeBorder? shape,
}) async {
  await prepareForOverlay(context);
  if (!context.mounted) return null;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    shape: shape,
    builder: builder,
  );
}
