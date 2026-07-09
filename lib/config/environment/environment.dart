import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';
import 'dev_config.dart';
import 'prod_config.dart';
import 'staging_config.dart';

/// Entornos disponibles.
/// Selección via `--dart-define=ENVIRONMENT=staging|prod` (default: dev).
enum Env { dev, staging, prod }

class Environment {
  Environment._();

  static final Environment instance = Environment._();

  late BaseConfig _config;
  BaseConfig get config => _config;

  /// Atajo rápido: `true` cuando la app usa datasources mock.
  bool get useMockData => _config.useMockData;

  Future<void> init() async {
    const envName =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

    final env = switch (envName) {
      'prod' => Env.prod,
      'staging' => Env.staging,
      _ => Env.dev,
    };

    final envFile = switch (env) {
      Env.prod => '.env.prod',
      Env.staging => '.env.staging',
      Env.dev => '.env.dev',
    };

    if (!kIsWeb) {
      await dotenv.load(fileName: envFile);
    }

    _config = switch (env) {
      Env.prod => ProdConfig(),
      Env.staging => StagingConfig(),
      Env.dev => DevConfig(),
    };
  }
}
