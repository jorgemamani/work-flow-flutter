import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
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
          content: Text(l.checkInTimeNote(DateFormat('HH:mm').format(DateTime.now()))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('confirmCheckIn'),
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.confirm),
            ),
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

    return LiveQuery<(List<CheckIn>, List<Employee>, Project?)>(
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
        final self = profile.employeeId != null;
        final qual = profile.qualificationStatus;
        final date = DateFormat('dd/MM');

        Future<void> pickOther() => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (c) => SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.8),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
                    children: [
                      SectionTitle(l.otherPeople, strong: true, padTop: false),
                      if (others.isEmpty)
                        EmptyState(icon: Icons.groups_outlined, text: l.noEmployees)
                      else
                        RuledList(
                          children: [
                            for (final e in others)
                              RowLink(
                                title: e.fullName,
                                chevron: false,
                                detail: StatusChip(
                                  e.onSite ? l.onSite : l.offSite,
                                  color: e.onSite ? AppColors.statusSuccess : AppColors.statusNeutral,
                                ),
                                trailing: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, AppSizes.buttonHeightSm),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(c);
                                    mark(type: e.onSite ? 'DOWN' : 'UP', employeeId: e.id, name: e.fullName, self: false);
                                  },
                                  child: Text(e.onSite ? l.registerDown : l.registerUp),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );

        return FieldScaffold(
          eyebrow: toBeginningOfSentenceCase(DateFormat.MMMMEEEEd().format(DateTime.now())),
          title: !self ? l.checkInTitle : (profile.onSite ? l.youAreOnSite : l.youAreOffSite),
          subtitle: project == null
              ? null
              : Text(project.name, style: const TextStyle(fontSize: 17, color: AppColors.ink)),
          footer: !self
              ? null
              : FieldFooter(
                  children: [
                    StreamBuilder<void>(
                      // La hora del botón se mantiene al día.
                      stream: Stream<void>.periodic(const Duration(seconds: 20)),
                      builder: (context, _) => AppButton(
                        key: const Key('selfCheckIn'),
                        height: AppSizes.rowHeight,
                        label: profile.onSite ? l.registerDown : l.registerUp,
                        subtitle: l.rightNowAt(DateFormat('HH:mm').format(DateTime.now())),
                        onPressed: projectId == null
                            ? null
                            : () => mark(
                                  type: profile.onSite ? 'DOWN' : 'UP',
                                  employeeId: profile.employeeId!,
                                  name: profile.fullName,
                                  self: true,
                                ),
                      ),
                    ),
                    if (canOthers)
                      TextButton(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                        ),
                        onPressed: pickOther,
                        child: Text(l.registerForOther),
                      ),
                  ],
                ),
          children: [
            if (self && qual != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.qualTitle, padTop: false),
                  RuledList(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Row(
                          children: [
                            Expanded(child: Text(l.qualRow, style: const TextStyle(fontSize: 16))),
                            switch (qual) {
                              'EXPIRED' => StatusChip(l.qualExpired, color: AppColors.statusError, fontSize: 15),
                              'EXPIRING' => StatusChip(l.qualExpiring, color: AppColors.statusWarning, fontSize: 15),
                              _ => StatusChip(l.qualOk, color: AppColors.statusSuccess, fontSize: 15),
                            },
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (qual == 'EXPIRED' && !profile.onSite) ...[
                    const SizedBox(height: 8),
                    FieldNotice(
                      icon: Icons.error_outline,
                      iconColor: AppColors.statusError,
                      child: Text(l.qualExpiredNote),
                    ),
                  ],
                ],
              ),
            if (history.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.lastRecords, padTop: false),
                  for (final c in history.take(6))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 56,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                c.occurredAt == null ? '' : date.format(c.occurredAt!.toLocal()),
                                style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(c.type == 'UP' ? l.wentUp : l.wentDown,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: c.isLocal
                                ? StatusChip(l.pendingSync, color: AppColors.statusWarning)
                                : Text(
                                    c.occurredAt == null ? '' : DateFormat('HH:mm').format(c.occurredAt!.toLocal()),
                                    style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (!self && canOthers) AppButton(label: l.registerForOther, onPressed: pickOther),
          ],
        );
      },
    );
  }
}
