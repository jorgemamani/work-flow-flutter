import 'package:flutter/material.dart';

import '../../../../shared/constants/app_branding.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/widgets/app_loading.dart';

/// Pantalla de carga inicial. La navegación post-splash la maneja el redirect
/// de GoRouter en función del estado de [AuthBloc].
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.work_rounded, color: Colors.white, size: 44),
              ),
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
