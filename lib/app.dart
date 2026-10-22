import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/sync/sync_coordinator.dart';
import 'dependency_injection.dart';
import 'features/account/locale_cubit.dart';
import 'features/auth/presentation/session_cubit.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'shared/constants/app_branding.dart';
import 'shared/constants/app_colors.dart';
import 'shared/constants/app_sizes.dart';
import 'shared/managers/alert_manager.dart';

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
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: ThemeMode.system,
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

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
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
