import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import 'tenant_brand.dart';

/// Siempre claro: la app se usa al sol. Botones de 56, campos de 56 y
/// radio 14. El color de la empresa ([brand]) es el acento: botón principal,
/// lo elegido, el foco y el avance; el texto queda en tinta.
ThemeData buildAppTheme(TenantBrand brand) {
  const ink = AppColors.ink;
  final radius = BorderRadius.circular(AppSizes.radiusMd);
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light, fontFamily: AppFonts.sans);
  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
        headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.15, color: ink),
        headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.15, color: ink),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ink),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
        titleSmall: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: const TextStyle(fontSize: 17, height: 1.45, color: ink),
        bodyMedium: const TextStyle(fontSize: 16, height: 1.4, color: ink),
        bodySmall: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
        labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink),
        labelMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
        labelSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ink),
      );
  WidgetStateProperty<T> picked<T>(T on, T off) =>
      WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? on : off);

  return base.copyWith(
    extensions: [brand],
    colorScheme: ColorScheme.light(
      primary: brand.fill,
      onPrimary: brand.on,
      primaryContainer: brand.fill,
      onPrimaryContainer: brand.on,
      secondary: brand.fill,
      onSecondary: brand.on,
      secondaryContainer: brand.fill,
      onSecondaryContainer: brand.on,
      surface: AppColors.surfaceLight,
      onSurface: ink,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.selected,
      surfaceTint: Colors.transparent,
      error: AppColors.statusError,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: text,
    iconTheme: const IconThemeData(color: ink, size: AppSizes.iconMd),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: brand.ink,
      selectionHandleColor: brand.ink,
      selectionColor: brand.fill.withValues(alpha: 0.3),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 17, fontWeight: FontWeight.w600, color: ink),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: radius, side: const BorderSide(color: AppColors.border)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: ink,
      minTileHeight: AppSizes.rowHeight,
      titleTextStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 16, fontWeight: FontWeight.w500, color: ink),
      subtitleTextStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 14, color: AppColors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 16),
      labelStyle: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
      floatingLabelStyle: TextStyle(fontSize: 16, color: brand.ink),
      hintStyle: const TextStyle(fontSize: 17, color: AppColors.textDisabled),
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.lineStrong, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.lineStrong, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: brand.ink, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.statusError, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.statusError, width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand.fill,
        foregroundColor: brand.on,
        disabledBackgroundColor: AppColors.disabledFill,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 17),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand.fill,
        foregroundColor: brand.on,
        disabledBackgroundColor: AppColors.disabledFill,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 17),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: brand.ink,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 17),
      ).copyWith(
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.disabled) ? AppColors.lineStrong : brand.ink, width: 1.5),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(AppSizes.tapTarget, AppSizes.tapTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
        textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(AppSizes.tapTarget, AppSizes.tapTarget),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.buttonHeightSm)),
        backgroundColor: picked(brand.fill, AppColors.surfaceLight),
        foregroundColor: picked(brand.on, ink),
        iconColor: picked(brand.on, ink),
        side: picked(BorderSide(color: brand.fill, width: 1.5), const BorderSide(color: AppColors.lineStrong, width: 1.5)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      color: picked(brand.fill, AppColors.surfaceLight),
      selectedColor: brand.fill,
      backgroundColor: AppColors.surfaceLight,
      checkmarkColor: brand.on,
      labelStyle: WidgetStateTextStyle.resolveWith(
        (s) => TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? brand.on : ink,
        ),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide(color: brand.fill, width: 1.5)
            : const BorderSide(color: AppColors.lineStrong, width: 1.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: picked(brand.fill, Colors.transparent),
      checkColor: WidgetStatePropertyAll(brand.on),
      side: const BorderSide(color: ink, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(fillColor: picked(brand.fill, ink)),
    switchTheme: SwitchThemeData(
      thumbColor: picked(brand.on, Colors.white),
      trackColor: picked(brand.fill, AppColors.lineStrong),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: brand.ink,
      linearTrackColor: AppColors.border,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 15, color: Colors.white),
      actionTextColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.lineStrong,
      dragHandleSize: Size(40, 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      titleTextStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      contentTextStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 16, height: 1.45, color: ink),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: AppColors.surfaceLight, surfaceTintColor: Colors.transparent),
    badgeTheme: const BadgeThemeData(backgroundColor: ink, textColor: Colors.white),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brand.fill,
      foregroundColor: brand.on,
      elevation: 2,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: ink,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: brand.ink,
      dividerColor: AppColors.border,
      labelStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}
