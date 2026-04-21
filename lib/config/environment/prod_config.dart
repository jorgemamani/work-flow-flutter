import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';

class ProdConfig implements BaseConfig {
  @override
  String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.workflow.com';

  @override
  int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
}
