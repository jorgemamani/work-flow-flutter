import 'package:flutter/material.dart';

import 'app.dart';
import 'config/environment/environment.dart';
import 'core/sync/sync_coordinator.dart';
import 'dependency_injection.dart';
import 'features/auth/presentation/session_cubit.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.instance.init();
  await configureDependencies();
  await sl<SyncCoordinator>().start();
  await sl<SessionCubit>().start();

  // El router se arma después de DI: lee el estado de sesión.
  appRouter = buildAppRouter();

  runApp(const WorkFlowApp());
}
