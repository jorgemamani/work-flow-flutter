import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../auth/presentation/session_cubit.dart';

/// Subida y bajada (PER-03): la propia siempre; la de otros con
/// `checkins.write_others` (RN-13). Se registra con la hora del teléfono.
class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final profile = session.profile!;
    final projectId = session.projectId;
    final canOthers = profile.can(Perms.checkinsWriteOthers, projectId: projectId);
    final repo = sl<FieldRepository>();

    Future<void> mark({required String type, required String employeeId, required String name, required bool self}) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(type == 'UP' ? l.confirmCheckUp(name) : l.confirmCheckDown(name)),
          content: Text(l.checkInTimeNote(DateFormat.Hm().format(DateTime.now()))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(key: const Key('confirmCheckIn'), onPressed: () => Navigator.pop(c, true), child: Text(l.confirm)),
          ],
        ),
      );
      if (ok != true || projectId == null || !context.mounted) return;
      final cubit = context.read<SessionCubit>();
      await sl<FieldActions>().checkIn(
        projectId: projectId,
        type: type,
        employeeId: employeeId,
        self: self,
        employeeName: name,
      );
      if (self) await cubit.applyLocalProfile(applySelfCheckIn(profile, type: type, projectId: projectId));
      if (context.mounted) showSaved(context);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.checkInTitle)),
      body: LiveQuery<(List<CheckIn>, List<Employee>, Project?)>(
        sources: const {'check_ins', 'employees', 'projects'},
        deps: [projectId, profile.onSite],
        query: () async => (
          profile.employeeId == null ? <CheckIn>[] : await repo.checkIns(profile.employeeId!),
          canOthers
              ? [
                  for (final e in (await repo.employees()).values)
                    if (e.id != profile.employeeId) e,
                ]
              : <Employee>[],
          await repo.project(projectId),
        ),
        builder: (context, d) {
          final (history, others, project) = d;
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              if (profile.employeeId != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      children: [
                        Icon(profile.onSite ? Icons.north : Icons.south, size: 40,
                            color: profile.onSite ? AppColors.statusSuccess : AppColors.textSecondary),
                        const SizedBox(height: AppSizes.sm),
                        Text(profile.onSite ? l.youAreOnSite : l.youAreOffSite,
                            style: context.textTheme.titleMedium),
                        if (project != null) Text(project.name, style: context.textTheme.bodyMedium),
                        const SizedBox(height: AppSizes.md),
                        FilledButton.icon(
                          key: const Key('selfCheckIn'),
                          icon: Icon(profile.onSite ? Icons.south : Icons.north),
                          label: Text(profile.onSite ? l.registerDown : l.registerUp),
                          onPressed: projectId == null
                              ? null
                              : () => mark(
                                    type: profile.onSite ? 'DOWN' : 'UP',
                                    employeeId: profile.employeeId!,
                                    name: profile.fullName,
                                    self: true,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  SectionTitle(l.myCheckIns),
                  Card(
                    child: Column(
                      children: [
                        for (final c in history.take(10))
                          ListTile(
                            dense: true,
                            leading: Icon(c.type == 'UP' ? Icons.north : Icons.south),
                            title: Text(c.type == 'UP' ? l.wentUp : l.wentDown),
                            subtitle: Text(c.occurredAt == null ? '' : DateFormat.yMMMd().add_Hm().format(c.occurredAt!)),
                            trailing: c.isLocal ? StatusChip(l.pendingSync, color: AppColors.primary) : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
              if (canOthers) ...[
                SectionTitle(l.otherPeople),
                if (others.isEmpty) EmptyState(icon: Icons.groups_outlined, text: l.noEmployees),
                for (final e in others)
                  Card(
                    child: ListTile(
                      title: Text(e.fullName),
                      subtitle: Text(e.onSite ? l.onSite : l.offSite),
                      trailing: TextButton(
                        onPressed: () => mark(
                          type: e.onSite ? 'DOWN' : 'UP',
                          employeeId: e.id,
                          name: e.fullName,
                          self: false,
                        ),
                        child: Text(e.onSite ? l.registerDown : l.registerUp),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
