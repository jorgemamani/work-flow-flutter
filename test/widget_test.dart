import 'package:flutter_test/flutter_test.dart';
import 'package:work_flow/shared/constants/app_branding.dart';

void main() {
  test('AppBranding tiene nombre correcto', () {
    expect(AppBranding.appName, 'WorkFlow');
  });
}
