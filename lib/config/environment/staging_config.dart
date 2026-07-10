import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';

class StagingConfig implements BaseConfig {
  @override
  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://arqytop-api.onrender.com';

  @override
  int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  @override
  bool get useMockData => false;
}
