import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/app_sizes.dart';
import '../../../shared/extensions/context_extensions.dart';
import 'session_cubit.dart';

/// Varias empresas (contrato §2): elegir con cuál trabajar.
class SelectTenantPage extends StatelessWidget {
  const SelectTenantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.chooseCompany),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.read<SessionCubit>().logout(),
        ),
      ),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(l.chooseCompanyHelp, style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSizes.md),
            for (final m in state.memberships)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(m.tenantName),
                  trailing: m.tenantId == state.profile?.tenantId
                      ? const Icon(Icons.check)
                      : const Icon(Icons.chevron_right),
                  onTap: state.busy
                      ? null
                      : () => context.read<SessionCubit>().chooseTenant(m.tenantId),
                ),
              ),
            if (state.busy)
              const Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  state.error == 'offline' ? l.loginOffline : state.error!,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
