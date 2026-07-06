import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/enums/app_user_role.dart';
import '../widgets/admin_dashboard_body.dart';
import '../widgets/employee_dashboard_body.dart';
import '../widgets/logistics_dashboard_body.dart';

/// Dispatcher de dashboard: elige el body correcto según rol y permisos.
/// La barra de navegación y el drawer viven en [AppShell], no aquí.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final perms = user.permissions;

        // Evaluamos permisos, no el rol como string.
        // Orden de prioridad: logística > admin/rrhh > empleado.
        if (user.role == AppUserRole.logistica) {
          return LogisticsDashboardBody(user: user);
        }

        final isManagerRole = perms.canWriteObras || perms.canWriteEmpleados;
        if (isManagerRole) {
          return AdminDashboardBody(user: user);
        }

        return EmployeeDashboardBody(user: user);
      },
    );
  }
}
