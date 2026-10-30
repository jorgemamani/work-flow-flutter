import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'common.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.isPassword = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.mono = false,
    this.note,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool isPassword;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  /// Números de documento y códigos: en mono y más grandes.
  final bool mono;

  /// Aclaración en gris junto a la etiqueta ("(opcional)").
  final String? note;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      maxLines: widget.obscureText || _obscureText ? 1 : widget.maxLines,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      // El teclado numérico no tiene "Listo": tocar afuera lo cierra.
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: widget.mono
          ? AppFonts.monoStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink)
          : const TextStyle(fontSize: 17, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : widget.suffixIcon,
      ),
    );
    // Etiqueta arriba, no flotante (ver FieldLabel).
    return FieldLabel(widget.label, note: widget.note, child: field);
  }
}
