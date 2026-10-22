import 'package:flutter/material.dart';

import '../../../shared/constants/app_branding.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/app_loading.dart';

/// Carga inicial. El router sale de acá según el estado de sesión.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_rounded, color: Colors.white, size: 56),
            const SizedBox(height: 24),
            Text(
              AppBranding.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const AppLoading(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
