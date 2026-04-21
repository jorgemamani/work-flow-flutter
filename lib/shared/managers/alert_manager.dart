import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AlertManager {
  AlertManager._();

  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setup({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _scaffoldMessengerKey = scaffoldMessengerKey;
    _navigatorKey = navigatorKey;
  }

  static void showSuccess(String message) {
    _show(message, AppColors.success);
  }

  static void showError(String message) {
    _show(message, AppColors.error);
  }

  static void showWarning(String message) {
    _show(message, AppColors.warning);
  }

  static void showInfo(String message) {
    _show(message, AppColors.info);
  }

  static void _show(String message, Color color) {
    _scaffoldMessengerKey?.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static Future<bool?> showConfirm({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) return null;

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
