import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';
import 'dev_config.dart';
import 'prod_config.dart';

enum Env { dev, prod }

class Environment {
  Environment._();

  static final Environment instance = Environment._();

  late BaseConfig _config;

  BaseConfig get config => _config;

  Future<void> init() async {
    const envName = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    const env = envName == 'prod' ? Env.prod : Env.dev;

    const envFile = env == Env.prod ? '.env.prod' : '.env.dev';

    if (!kIsWeb) {
      await dotenv.load(fileName: envFile);
    }

    _config = env == Env.prod ? ProdConfig() : DevConfig();
  }
}
