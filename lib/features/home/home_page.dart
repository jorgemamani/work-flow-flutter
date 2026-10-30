import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/theme/tenant_brand.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/connection_strip.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/live_query.dart';
import '../../shared/widgets/tenant_mark.dart';
import '../auth/presentation/session_cubit.dart';
import 'home_actions.dart';

class _HomeData {
  const _HomeData({
    this.project,
    required this.projects,
    required this.incoming,
    required this.incomingItems,
    required this.mine,
    required this.schedules,
    required this.lastUp,
    required this.dailyLogToday,
  });

  final Project? project;
  final List<Project> projects;
  final List<Remito> incoming;
  final Map<String, int> incomingItems;
  final int mine;
  final List<VerificationSchedule> schedules;
  final DateTime? lastUp;
  final bool dailyLogToday;
}

/// Inicio: dónde estoy (arriba o abajo, en qué proyecto), qué tengo para
/// hacer y accesos a todo lo que se hace en campo.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = sl<FieldRepository>();
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final profile = session.profile!;
        final projectId = session.projectId;
        final employeeId = profile.employeeId;
        return LiveQuery<_HomeData>(
          deps: [projectId, employeeId, profile.onSite],
          query: () async {
            final incoming = projectId == null ? <Remito>[] : await repo.incomingRemitos(projectId);
            final now = DateTime.now();
            final checkIns = employeeId == null ? <CheckIn>[] : await repo.checkIns(employeeId);
            return _HomeData(
              project: await repo.project(projectId),
              projects: await repo.projects(),
              incoming: incoming,
              incomingItems: {for (final r in incoming) r.id: (await repo.remitoItems(r.id)).length},
              mine: employeeId == null ? 0 : (await repo.myAssets(employeeId)).length,
              schedules: projectId == null
                  ? []
                  : [
                      for (final s in await repo.schedules(projectId))
                        if (s.nextDueAt != null && s.nextDueAt!.difference(now).inDays < 7) s,
                    ],
              lastUp: [for (final c in checkIns) if (c.type == 'UP') c.occurredAt].firstOrNull,
              dailyLogToday: (await repo.submissions(type: 'DAILY_LOG'))
                  .any((s) => (s.isLocal || s.authorEmployeeId == employeeId) && s.occurredAt != null && _sameDay(s.occurredAt!.toLocal(), now)),
            );
          },
          builder: (context, d) => FieldScaffold(
            showBack: false,
            title: l.helloName(profile.firstName),
            subtitle: Text(profile.tenantName),
            titleTrailing: const TenantMark(size: 40),
            onRefresh: () => context.read<SyncCoordinator>().syncNow(),
            gap: 22,
            children: [
              _ProjectCard(data: d, profile: profile),
              if (projectId == null)
                BlocBuilder<SyncCoordinator, SyncStatus>(
                  builder: (context, s) => EmptyState(
                    icon: s.syncing ? Icons.downloading : Icons.landscape_outlined,
                    text: s.syncing ? l.downloadingProject : l.noProject,
                  ),
                )
              else ...[
                _Todo(data: d, profile: profile, projectId: projectId),
                ..._actionSections(context, HomeActions.of(profile, projectId)),
                if (employeeId != null)
                  RuledList(
                    children: [
                      RowLink(
                        title: l.myItems,
                        trailing: Text(l.itemsCount(d.mine), style: AppFonts.monoStyle(color: AppColors.textSecondary)),
                        onTap: () => context.go(RouteNames.items),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Todo extends StatelessWidget {
  const _Todo({required this.data, required this.profile, required this.projectId});

  final _HomeData data;
  final Profile profile;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = DateFormat('dd/MM');
    bool can(String p) => profile.can(p, projectId: projectId);
    final failed = context.select((SyncCoordinator c) => c.state.counts.failed);
    final rows = <Widget>[
      if (failed > 0)
        RowLink(
          leading: const StatusDot(AppColors.statusError, size: 9),
          title: l.failedCount(failed),
          detail: Text(l.homeReviewSync),
          onTap: () => context.push(RouteNames.sync),
        ),
      if (can(Perms.remitosConfirm))
        for (final r in data.incoming.take(3))
          RowLink(
            leading: const StatusDot(AppColors.statusMove, size: 9),
            title: l.homeReceiveRemito(r.displayNumber),
            detail: Text([
              l.itemsCount(data.incomingItems[r.id] ?? 0),
              if (r.dispatchedAt != null) l.dispatchedAgo(timeAgo(context, r.dispatchedAt!)),
            ].join(' · ')),
            onTap: () => context.push(RouteNames.receiveRemito(r.id)),
          ),
      if (can(Perms.verificationsSubmit))
        for (final s in data.schedules)
          RowLink(
            leading: const StatusDot(AppColors.statusWarning, size: 9),
            title: s.name,
            detail: Text(l.homeDueOn(date.format(s.nextDueAt!.toLocal()))),
            onTap: () => context.push(RouteNames.newVerification),
          ),
      if (can(Perms.submissionsCreate) && profile.onSite && !data.dailyLogToday)
        RowLink(
          leading: const StatusDot(AppColors.statusNeutral, size: 9),
          title: l.homeDailyLogToday,
          detail: Text(l.homeDailyLogMissing),
          onTap: () => context.push(RouteNames.newDailyLog),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.homeTodo, strong: true, padTop: false),
        if (rows.isEmpty)
          RuledList(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(l.homeNothingTodo, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              ),
            ],
          )
        else
          RuledList(children: rows),
      ],
    );
  }
}

/// Acciones del inicio. Con acciones de los dos lados, dos secciones con
/// título; si no, una sola ("Qué querés hacer"). Escanear está en la barra y
/// la subida en la tarjeta del proyecto.
List<Widget> _actionSections(BuildContext context, HomeActions a) {
  final l = context.l10n;
  _Action? build(HomeAction action) => switch (action) {
        HomeAction.scan || HomeAction.checkIn => null,
        HomeAction.receiveRemito => _Action(Icons.local_shipping_outlined, l.actionReceiveRemito,
            () => context.push(RouteNames.incomingRemitos), key: 'receive'),
        HomeAction.verification => _Action(Icons.photo_camera_outlined, l.actionVerification,
            () => context.push(RouteNames.newVerification), key: 'verification'),
        HomeAction.dailyLog => _Action(Icons.description_outlined, l.actionDailyLog, () => context.push(RouteNames.newDailyLog), key: 'dailyLog'),
        HomeAction.incident => _Action(Icons.warning_amber_rounded, l.actionIncident,
            () => context.push(RouteNames.newIncident), key: 'incident'),
        HomeAction.newItem => _Action(Icons.add_box_outlined, l.newItem, () => context.push(RouteNames.newItem), key: 'newItem'),
        HomeAction.requirement => _Action(Icons.add, l.actionRequirement,
            () => context.push(RouteNames.newRequirement), key: 'requirement'),
        HomeAction.returnRemito => _Action(Icons.undo, l.actionReturn,
            () => context.push(RouteNames.returnRemito), key: 'return'),
      };
  List<_Action> all(List<HomeAction> xs) => [for (final x in xs) if (build(x) case final a?) a];
  Widget section(String title, List<_Action> actions) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionTitle(title, strong: true, padTop: false), const SizedBox(height: 2), _ActionGrid(actions: actions)],
      );
  final project = all(a.project);
  final logistics = all(a.logistics);
  if (project.isEmpty || logistics.isEmpty) {
    final only = [...project, ...logistics];
    return [if (only.isNotEmpty) section(l.quickActions, only)];
  }
  return [section(l.sectionProject, project), section(l.sectionLogistics, logistics)];
}

/// Tarjeta en el color de la empresa: arriba o abajo, en qué proyecto. Abre la subida y bajada.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data, required this.profile});

  final _HomeData data;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = data.project;
    final employee = profile.employeeId != null;
    final canCheckIn = employee && profile.can(Perms.checkinsSelf);
    final brand = context.brand;
    final on = brand.on;
    return Material(
      color: brand.fill,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        key: const Key('action-checkIn'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: canCheckIn ? () => context.push(RouteNames.checkIn) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (employee) ...[
                Row(
                  children: [
                    // Sobre el color de la empresa el punto va en el color del texto: el
                    // estado lo dice la palabra.
                    StatusDot(profile.onSite ? on : on.withValues(alpha: 0.45)),
                    const SizedBox(width: 8),
                    Text(
                      profile.onSite ? l.onSite : l.offSite,
                      key: const Key('onSiteStatus'),
                      style: TextStyle(fontSize: 14, color: on.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p?.name ?? l.noProjectShort,
                      key: const Key('currentProject'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: on),
                    ),
                  ),
                  if (data.projects.length > 1)
                    IconButton(
                      tooltip: l.changeProject,
                      icon: Icon(Icons.swap_horiz, color: on),
                      onPressed: () => _pickProject(context),
                    ),
                ],
              ),
              if (canCheckIn) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: profile.onSite && data.lastUp != null
                          ? Text(
                              l.homeUpSince(DateFormat('dd/MM').format(data.lastUp!.toLocal())),
                              style: TextStyle(fontSize: 15, color: on),
                            )
                          : Text(
                              profile.onSite ? l.actionCheckDown : l.actionCheckUp,
                              style: TextStyle(fontSize: 15, color: on),
                            ),
                    ),
                    Icon(Icons.chevron_right, color: on),
                  ],
                ),
              ],
            ],
          ),
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
          padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
          children: [
            SectionTitle(context.l10n.changeProject, strong: true, padTop: false),
            RuledList(
              children: [
                for (final p in data.projects)
                  RowLink(
                    title: p.name,
                    chevron: false,
                    trailing: p.id == data.project?.id ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(c, p.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (id != null) await cubit.selectProject(id);
  }
}

class _Action {
  const _Action(this.icon, this.label, this.onTap, {required this.key});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String key;
}

/// Dos columnas de botones de 64 con ícono y texto.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    Widget tile(_Action a) => Material(
          color: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            key: Key('action-${a.key}'),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: a.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Icon(a.icon, size: 22, color: context.brand.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Column(
      children: [
        for (var i = 0; i < actions.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(actions[i])),
                const SizedBox(width: 8),
                Expanded(child: i + 1 < actions.length ? tile(actions[i + 1]) : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
