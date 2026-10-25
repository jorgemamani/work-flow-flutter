import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/connection_strip.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/live_query.dart';
import '../auth/presentation/session_cubit.dart';

/// Remitos en tránsito hacia el proyecto, para confirmar su llegada, y los
/// últimos que se tocaron desde el teléfono.
class IncomingRemitosPage extends StatelessWidget {
  const IncomingRemitosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final projectId = context.watch<SessionCubit>().state.projectId;
    final repo = sl<FieldRepository>();
    return LiveQuery<(List<Remito>, List<Remito>, Map<String, Location>, Map<String, int>, Project?)>(
      sources: const {'remitos', 'remito_items', 'locations', 'projects'},
      deps: [projectId],
      query: () async {
        final all = projectId == null ? <Remito>[] : await repo.projectRemitos(projectId);
        final incoming = projectId == null ? <Remito>[] : await repo.incomingRemitos(projectId);
        return (
          incoming,
          [
            for (final r in all)
              if (r.hasPendingChange || r.type == 'RETURN') r,
          ],
          await repo.locations(),
          {for (final r in incoming) r.id: (await repo.remitoItems(r.id)).length},
          await repo.project(projectId),
        );
      },
      builder: (context, d) {
        final (incoming, recent, locs, counts, project) = d;
        String place(String? id) => locs[id]?.name ?? '—';
        return FieldScaffold(
          title: l.remitosTitle,
          subtitle: project == null ? null : Text(l.remitosTowards(project.name)),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(l.toReceiveCount(incoming.length), strong: true, padTop: false),
                if (incoming.isEmpty)
                  RuledList(children: [EmptyState(icon: Icons.local_shipping_outlined, text: l.noIncomingRemitos)])
                else
                  RuledList(
                    children: [
                      for (final r in incoming)
                        InkWell(
                          key: Key('remito-${r.number}'),
                          onTap: () => context.push(RouteNames.receiveRemito(r.id)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Chapa(r.displayNumber, fontSize: 14),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(l.remitoType(r.type),
                                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                                    ),
                                    StatusChip(l.remitoStatus(r.status), color: remitoStatusColor(r.status)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l.fromTo(place(r.originId), place(r.destinationId)),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.dispatchedAt == null ? '' : l.dispatchedAgo(timeAgo(context, r.dispatchedAt!)),
                                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Text(l.itemsCount(counts[r.id] ?? 0),
                                        style: AppFonts.monoStyle(fontSize: 14, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (recent.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.recentRemitos, strong: true, padTop: false),
                  RuledList(
                    children: [
                      for (final r in recent)
                        RowLink(
                          leading: Chapa(r.displayNumber, fontSize: 14),
                          title: l.remitoType(r.type),
                          detail: Wrap(
                            spacing: 12,
                            children: [
                              StatusChip(l.remitoStatus(r.status), color: remitoStatusColor(r.status)),
                              if (r.hasPendingChange) StatusChip(l.pendingSync, color: AppColors.statusWarning),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
