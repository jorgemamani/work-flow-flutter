import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_coordinator.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/common.dart';
import '../auth/presentation/session_cubit.dart';
import 'locale_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _switchTenant(BuildContext context) async {
    final l = context.l10n;
    final cubit = context.read<SessionCubit>();
    final profile = cubit.state.profile!;
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l.chooseCompany, style: const TextStyle(fontWeight: FontWeight.w600))),
            for (final m in profile.memberships)
              ListTile(
                leading: const Icon(Icons.business),
                title: Text(m.tenantName),
                trailing: m.tenantId == profile.tenantId ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, m.tenantId),
              ),
          ],
        ),
      ),
    );
    if (id == null || id == profile.tenantId) return;
    final ok = await cubit.switchTenant(id);
    if (!ok && context.mounted) {
      final err = cubit.state.error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(switch (err) {
          'pendingBlocksSwitch' => l.pendingBlocksSwitch,
          'offline' => l.needsConnection,
          _ => err ?? '',
        }),
      ));
      cubit.clearError();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l = context.l10n;
    final pending = context.read<SyncCoordinator>().state.counts.pending;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.logout),
        content: Text(pending > 0 ? l.logoutWithPending(pending) : l.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.logout)),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<SessionCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = context.watch<SessionCubit>().state.profile!;
    final locale = context.watch<LocaleCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabAccount)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(profile.firstName.isEmpty ? '?' : profile.firstName[0])),
              title: Text(profile.fullName),
              subtitle: Text([
                profile.tenantName,
                if (profile.documentNumber != null) l.dniValue(profile.documentNumber!),
                if (profile.email != null) profile.email!,
              ].join('\n')),
              isThreeLine: true,
            ),
          ),
          SectionTitle(l.settings),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l.syncTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.sync),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(l.changePin),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.changePin),
                ),
                if (profile.memberships.length > 1) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(l.switchCompany),
                    subtitle: Text(profile.tenantName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _switchTenant(context),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.language),
                  trailing: DropdownButton<String?>(
                    value: locale?.languageCode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.languageSystem)),
                      const DropdownMenuItem(value: 'es', child: Text('Español')),
                      const DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) => context.read<LocaleCubit>().set(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.logout),
            label: Text(l.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
