import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../auth/presentation/session_cubit.dart';

/// Registros: bitácoras, verificaciones, informes recibidos, incidencias y
/// solicitudes. Todo leído de la base local; lo no enviado se marca.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final profile = session.profile!;
    final canRequest = profile.can(Perms.requirementsCreate, projectId: session.projectId);
    final tabs = <(String, Widget)>[
      (l.tabDailyLogs, _SubmissionList(type: 'DAILY_LOG', empty: l.noDailyLogs, newRoute: RouteNames.newDailyLog)),
      (l.tabVerifications, _SubmissionList(type: 'VERIFICATION', empty: l.noVerifications, newRoute: RouteNames.newVerification)),
      (l.receivedReports, _ReceivedReports(employeeId: profile.employeeId)),
      (l.tabIncidents, const _IncidentList()),
      if (canRequest) (l.tabRequirements, const _RequirementList()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.tabRecords),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: t.$1)],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.$2]),
      ),
    );
  }
}

const _submissionSources = {'submissions', 'incident_details', 'requirements', 'verification_lines'};

String _date(BuildContext context, DateTime? d) =>
    d == null ? '' : DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm().format(d);

Widget _pendingChip(BuildContext context, Model m) =>
    m.hasPendingChange ? StatusChip(context.l10n.pendingSync, color: AppColors.statusWarning) : const SizedBox.shrink();

class _SubmissionList extends StatelessWidget {
  const _SubmissionList({required this.type, required this.empty, required this.newRoute});

  final String type;
  final String empty;
  final String newRoute;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-$type',
        onPressed: () => context.push(newRoute),
        child: const Icon(Icons.add),
      ),
      body: LiveQuery<List<Submission>>(
        sources: _submissionSources,
        query: () => sl<FieldRepository>().submissions(type: type),
        builder: (context, list) {
          final mine = [
            for (final s in list)
              if (s.direction != 'COMPANY_TO_EMPLOYEE') s,
          ];
          if (mine.isEmpty) return EmptyState(icon: Icons.assignment_outlined, text: empty);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: mine.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) {
              final s = mine[i];
              final lines = s.payload['_lines'];
              return Card(
                child: ListTile(
                  title: Text(
                    s.text.isNotEmpty ? s.text : (s.title ?? l.submissionType(s.type)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text([
                    _date(context, s.occurredAt),
                    if (lines is int) l.itemsCount(lines),
                  ].join(' · ')),
                  trailing: s.hasPendingChange
                      ? _pendingChip(context, s)
                      : StatusChip(l.reviewStatus(s.reviewStatus), color: reviewStatusColor(s.reviewStatus)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReceivedReports extends StatelessWidget {
  const _ReceivedReports({required this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = employeeId;
    if (id == null) return EmptyState(icon: Icons.mark_email_read_outlined, text: l.noReceivedReports);
    return LiveQuery<List<Submission>>(
      sources: _submissionSources,
      query: () => sl<FieldRepository>().receivedReports(id),
      builder: (context, list) {
        if (list.isEmpty) return EmptyState(icon: Icons.mark_email_read_outlined, text: l.noReceivedReports);
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, i) {
            final s = list[i];
            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(s.title ?? l.submissionType(s.type)),
                subtitle: Text(_date(context, s.occurredAt)),
                childrenPadding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(s.text.isEmpty ? '—' : s.text)],
              ),
            );
          },
        );
      },
    );
  }
}

class _IncidentList extends StatelessWidget {
  const _IncidentList();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = sl<FieldRepository>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-incident',
        onPressed: () => context.push(RouteNames.newIncident),
        child: const Icon(Icons.add),
      ),
      body: LiveQuery<(List<Submission>, Map<String, IncidentDetail>)>(
        sources: _submissionSources,
        query: () async => (await repo.submissions(type: 'INCIDENT'), await repo.incidentDetails()),
        builder: (context, d) {
          final (list, details) = d;
          if (list.isEmpty) return EmptyState(icon: Icons.report_problem_outlined, text: l.noIncidents);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) {
              final s = list[i];
              final det = details[s.id];
              final kind = det?.kind ?? s.payload['_kind'] as String? ?? 'OTHER';
              final sev = det?.severity ?? s.payload['_severity'] as String?;
              return Card(
                child: ListTile(
                  title: Text(s.title ?? l.incidentKind(kind)),
                  subtitle: Text([
                    l.incidentKind(kind),
                    if (sev != null) l.severity(sev),
                    _date(context, s.occurredAt),
                  ].join(' · ')),
                  trailing: det == null || s.hasPendingChange
                      ? _pendingChip(context, s)
                      : StatusChip(l.incidentStatus(det.status), color: incidentStatusColor(det.status)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequirementList extends StatelessWidget {
  const _RequirementList();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-requirement',
        onPressed: () => context.push(RouteNames.newRequirement),
        child: const Icon(Icons.add),
      ),
      body: LiveQuery<List<Requirement>>(
        sources: _submissionSources,
        query: () => sl<FieldRepository>().requirements(),
        builder: (context, list) {
          if (list.isEmpty) return EmptyState(icon: Icons.add_shopping_cart, text: l.noRequirements);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                child: ListTile(
                  title: Text(l.requirementKind(r.kind)),
                  subtitle: Text([
                    _date(context, r.requestedAt),
                    if (r.notes != null && r.notes!.isNotEmpty) r.notes!,
                  ].join(' · ')),
                  trailing: r.hasPendingChange
                      ? _pendingChip(context, r)
                      : StatusChip(l.requirementStatus(r.status), color: requirementStatusColor(r.status)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
