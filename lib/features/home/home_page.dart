import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../auth/presentation/session_cubit.dart';
import 'home_actions.dart';

class _HomeData {
  const _HomeData({
    this.project,
    required this.projects,
    required this.incoming,
    required this.received,
    required this.mine,
    required this.projectItems,
  });

  final Project? project;
  final List<Project> projects;
  final int incoming;
  final int received;
  final int mine;
  final int projectItems;
}

/// Inicio: proyecto actual y estado (arriba/abajo, sync), y accesos a todo
/// lo que se hace en campo.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = sl<FieldRepository>();
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final profile = session.profile!;
        final projectId = session.projectId;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.helloName(profile.firstName)),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<SyncCoordinator>().syncNow(),
            child: LiveQuery<_HomeData>(
              deps: [projectId, profile.employeeId],
              query: () async {
                final employeeId = profile.employeeId;
                return _HomeData(
                  project: await repo.project(projectId),
                  projects: await repo.projects(),
                  incoming: projectId == null ? 0 : (await repo.incomingRemitos(projectId)).length,
                  received: employeeId == null ? 0 : (await repo.receivedReports(employeeId)).length,
                  mine: employeeId == null ? 0 : (await repo.myAssets(employeeId)).length,
                  projectItems: projectId == null ? 0 : (await repo.projectAssets(projectId)).length,
                );
              },
              builder: (context, d) => ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  _ProjectCard(data: d, profile: profile),
                  if (projectId == null)
                    BlocBuilder<SyncCoordinator, SyncStatus>(
                      builder: (context, s) => Padding(
                        padding: const EdgeInsets.only(top: AppSizes.lg),
                        child: EmptyState(
                          icon: s.syncing ? Icons.downloading : Icons.landscape_outlined,
                          text: s.syncing ? l.downloadingProject : l.noProject,
                        ),
                      ),
                    )
                  else ...[
                    ..._actionSections(context, HomeActions.of(profile, projectId), profile, d),
                    SectionTitle(l.summary),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.back_hand_outlined),
                            title: Text(l.myItems),
                            trailing: Text('${d.mine}'),
                            onTap: () => context.go(RouteNames.items),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(l.projectItems),
                            trailing: Text('${d.projectItems}'),
                            onTap: () => context.go(RouteNames.items),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.mark_email_unread_outlined),
                            title: Text(l.receivedReports),
                            trailing: Text('${d.received}'),
                            onTap: () => context.go(RouteNames.records),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Acciones del inicio. Con acciones de los dos lados, dos secciones con
/// título; si no, una sola ("Qué querés hacer").
List<Widget> _actionSections(BuildContext context, HomeActions a, Profile profile, _HomeData d) {
  final l = context.l10n;
  _Action build(HomeAction action) => switch (action) {
        HomeAction.scan => _Action(Icons.qr_code_scanner, l.actionScan, () => context.push(RouteNames.scan), key: 'scan'),
        HomeAction.receiveRemito => _Action(Icons.local_shipping_outlined, l.actionReceiveRemito,
            () => context.push(RouteNames.incomingRemitos),
            badge: d.incoming, key: 'receive'),
        HomeAction.verification => _Action(Icons.fact_check_outlined, l.actionVerification,
            () => context.push(RouteNames.newVerification), key: 'verification'),
        HomeAction.dailyLog => _Action(Icons.edit_note, l.actionDailyLog, () => context.push(RouteNames.newDailyLog), key: 'dailyLog'),
        HomeAction.incident => _Action(Icons.report_problem_outlined, l.actionIncident,
            () => context.push(RouteNames.newIncident), key: 'incident'),
        HomeAction.checkIn => _Action(profile.onSite ? Icons.south : Icons.north,
            profile.onSite ? l.actionCheckDown : l.actionCheckUp, () => context.push(RouteNames.checkIn), key: 'checkIn'),
        HomeAction.newItem => _Action(Icons.add_box_outlined, l.newItem, () => context.push(RouteNames.newItem), key: 'newItem'),
        HomeAction.requirement => _Action(Icons.add_shopping_cart, l.actionRequirement,
            () => context.push(RouteNames.newRequirement), key: 'requirement'),
        HomeAction.returnRemito => _Action(Icons.assignment_return_outlined, l.actionReturn,
            () => context.push(RouteNames.returnRemito), key: 'return'),
      };
  if (!a.showSections) {
    return [
      SectionTitle(l.quickActions),
      _ActionGrid(actions: [for (final x in [...a.project, ...a.logistics]) build(x)]),
    ];
  }
  return [
    SectionTitle(l.sectionProject),
    _ActionGrid(actions: [for (final x in a.project) build(x)]),
    SectionTitle(l.sectionLogistics),
    _ActionGrid(actions: [for (final x in a.logistics) build(x)]),
  ];
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data, required this.profile});

  final _HomeData data;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = data.project;
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.landscape, color: Colors.white),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    p?.name ?? l.noProjectShort,
                    key: const Key('currentProject'),
                    style: context.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (data.projects.length > 1)
                  IconButton(
                    tooltip: l.changeProject,
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    onPressed: () => _pickProject(context),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(profile.tenantName, style: const TextStyle(color: Colors.white70)),
            if (profile.employeeId != null) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(profile.onSite ? Icons.north : Icons.south, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      profile.onSite ? l.onSite : l.offSite,
                      key: const Key('onSiteStatus'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickProject(BuildContext context) async {
    final cubit = context.read<SessionCubit>();
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in data.projects)
              ListTile(
                leading: const Icon(Icons.landscape_outlined),
                title: Text(p.name),
                trailing: p.id == data.project?.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, p.id),
              ),
          ],
        ),
      ),
    );
    if (id != null) await cubit.selectProject(id);
  }
}

class _Action {
  const _Action(this.icon, this.label, this.onTap, {this.badge = 0, required this.key});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final String key;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSizes.sm,
      crossAxisSpacing: AppSizes.sm,
      childAspectRatio: 1,
      children: [
        for (final a in actions)
          Card(
            child: InkWell(
              key: Key('action-${a.key}'),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: a.onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Badge(
                      isLabelVisible: a.badge > 0,
                      label: Text('${a.badge}'),
                      child: Icon(a.icon, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
