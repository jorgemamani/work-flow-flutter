import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'core/sync/sync_coordinator.dart';
import 'dependency_injection.dart';
import 'features/account/locale_cubit.dart';
import 'features/auth/presentation/session_cubit.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'shared/constants/app_branding.dart';
import 'shared/constants/app_colors.dart';
import 'shared/constants/app_fonts.dart';
import 'shared/constants/app_sizes.dart';
import 'shared/managers/alert_manager.dart';
import 'shared/widgets/connection_strip.dart';

class WorkFlowApp extends StatefulWidget {
  const WorkFlowApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  State<WorkFlowApp> createState() => _WorkFlowAppState();
}

class _WorkFlowAppState extends State<WorkFlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app: mandar lo pendiente y traer novedades.
    if (state == AppLifecycleState.resumed) sl<SyncCoordinator>().kick();
  }

  @override
  Widget build(BuildContext context) {
    AlertManager.setup(
      scaffoldMessengerKey: WorkFlowApp.scaffoldMessengerKey,
      navigatorKey: rootNavigatorKey,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: sl<SessionCubit>()),
        BlocProvider<SyncCoordinator>.value(value: sl<SyncCoordinator>()),
        BlocProvider<LocaleCubit>(create: (_) => LocaleCubit(sl())..load()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) => MaterialApp.router(
          title: AppBranding.displayTitle,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: WorkFlowApp.scaffoldMessengerKey,
          theme: _buildTheme(),
          themeMode: ThemeMode.light,
          routerConfig: appRouter,
          scrollBehavior: _AppScrollBehavior(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          // Fechas (DateFormat) en el idioma de la app, no en el default de intl.
          builder: (context, child) {
            Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
            return ConnectionFrame(child: child!);
          },
          localeResolutionCallback: (device, supported) {
            for (final l in supported) {
              if (l.languageCode == device?.languageCode) return l;
            }
            return const Locale('es');
          },
        ),
      ),
    );
  }

  /// Siempre claro: la app se usa al sol. Botones de 56, campos de 56 y
  /// radio 14; tinta para la acción principal y lo elegido.
  ThemeData _buildTheme() {
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
      colorScheme: const ColorScheme.light(
        primary: ink,
        onPrimary: Colors.white,
        secondary: ink,
        onSecondary: Colors.white,
        secondaryContainer: ink,
        onSecondaryContainer: Colors.white,
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
      textSelectionTheme: const TextSelectionThemeData(cursorColor: ink, selectionHandleColor: ink),
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
        floatingLabelStyle: const TextStyle(fontSize: 16, color: ink),
        hintStyle: const TextStyle(fontSize: 17, color: AppColors.textDisabled),
        border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.lineStrong, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.lineStrong, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: ink, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.statusError, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.statusError, width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
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
          backgroundColor: ink,
          foregroundColor: Colors.white,
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
          foregroundColor: ink,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 17),
        ).copyWith(
          side: WidgetStateBorderSide.resolveWith(
            (s) => BorderSide(color: s.contains(WidgetState.disabled) ? AppColors.lineStrong : ink, width: 1.5),
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
          backgroundColor: picked(ink, AppColors.surfaceLight),
          foregroundColor: picked(Colors.white, ink),
          side: picked(const BorderSide(color: ink, width: 1.5), const BorderSide(color: AppColors.lineStrong, width: 1.5)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        color: picked(ink, AppColors.surfaceLight),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (s) => TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? Colors.white : ink,
          ),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const BorderSide(color: ink, width: 1.5)
              : const BorderSide(color: AppColors.lineStrong, width: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: picked(ink, Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: ink, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(ink)),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: picked(ink, AppColors.lineStrong),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ink,
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
    );
  }
}

class _AppScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
