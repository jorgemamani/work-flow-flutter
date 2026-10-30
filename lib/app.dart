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
import 'shared/managers/alert_manager.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/tenant_brand.dart';
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
      // El tema sale de la empresa de la sesión: cambia al ingresar o al
      // cambiar de empresa.
      child: BlocSelector<SessionCubit, SessionState, String?>(
        selector: (s) => s.profile?.tenantBrandColor,
        builder: (context, brandColor) => BlocBuilder<LocaleCubit, Locale?>(
          builder: (context, locale) => MaterialApp.router(
            title: AppBranding.displayTitle,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: WorkFlowApp.scaffoldMessengerKey,
            theme: buildAppTheme(TenantBrand.from(brandColor)),
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
