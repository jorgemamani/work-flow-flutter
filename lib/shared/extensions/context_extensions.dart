import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isWeb => kIsWeb;
  bool get isMobile => screenWidth < AppSizes.mobileFrame;
  bool get isTablet => screenWidth >= AppSizes.mobileFrame && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
}
