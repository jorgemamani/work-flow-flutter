import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'config/environment/environment.dart';
import 'dependency_injection.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Environment.instance.init();
  await configureDependencies();

  // El router se construye después de DI para que sl<AuthBloc>() esté disponible.
  appRouter = buildAppRouter();

  runApp(const WorkFlowApp());
}
