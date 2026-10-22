import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';

class DevConfig implements BaseConfig {
  /// `--dart-define=API_BASE_URL=http://localhost:3103` para una API local.
  static const _override = String.fromEnvironment('API_BASE_URL');

  @override
  String get apiBaseUrl => _override.isNotEmpty
      ? _override
      : dotenv.env['API_BASE_URL'] ?? 'https://arqytop-api.onrender.com';

  @override
  int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '15000') ?? 15000;
}
