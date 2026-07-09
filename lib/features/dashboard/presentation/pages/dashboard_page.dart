import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../widgets/admin_dashboard_body.dart';
import '../widgets/employee_dashboard_body.dart';
import '../widgets/logistics_dashboard_body.dart';

/// Dispatcher de dashboard: elige el body correcto según permisos, no según rol.
///
/// Orden de prioridad (de mayor a menor privilegio):
/// 1. Puede gestionar inventario pero NO obras/empleados → vista de logística.
/// 2. Puede gestionar obras o empleados → vista admin/RRHH.
/// 3. Resto → vista de empleado de campo.
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

        final perms = state.user.permissions;

        if (perms.canWriteInventory &&
            !perms.canWriteObras &&
            !perms.canWriteEmpleados) {
          return LogisticsDashboardBody(user: state.user);
        }

        if (perms.canWriteObras || perms.canWriteEmpleados) {
          return AdminDashboardBody(user: state.user);
        }

        return EmployeeDashboardBody(user: state.user);
      },
    );
  }
}
