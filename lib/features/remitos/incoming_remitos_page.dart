import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '../../shared/widgets/sync_indicator.dart';
import '../auth/presentation/session_cubit.dart';

/// Remitos en tránsito hacia el proyecto, para confirmar su llegada.
class IncomingRemitosPage extends StatelessWidget {
  const IncomingRemitosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final projectId = context.watch<SessionCubit>().state.projectId;
    final repo = sl<FieldRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l.incomingRemitos), actions: const [SyncIndicator()]),
      body: LiveQuery<(List<Remito>, List<Remito>, Map<String, Location>)>(
        sources: const {'remitos', 'remito_items', 'locations'},
        deps: [projectId],
        query: () async {
          final all = projectId == null ? <Remito>[] : await repo.projectRemitos(projectId);
          return (
            projectId == null ? <Remito>[] : await repo.incomingRemitos(projectId),
            [
              for (final r in all)
                if (r.hasPendingChange || r.type == 'RETURN') r,
            ],
            await repo.locations(),
          );
        },
        builder: (context, d) {
          final (incoming, recent, locs) = d;
          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              if (incoming.isEmpty)
                EmptyState(icon: Icons.local_shipping_outlined, text: l.noIncomingRemitos)
              else
                for (final r in incoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Card(
                      child: ListTile(
                        key: Key('remito-${r.number}'),
                        leading: const Icon(Icons.local_shipping, color: AppColors.primary),
                        title: Text('${l.remitoType(r.type)} ${r.displayNumber}'),
                        subtitle: Text([
                          l.fromTo(locs[r.originId]?.name ?? '—', locs[r.destinationId]?.name ?? '—'),
                          if (r.dispatchedAt != null) l.dispatchedAgo(timeAgo(context, r.dispatchedAt!)),
                        ].join('\n')),
                        isThreeLine: r.dispatchedAt != null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(RouteNames.receiveRemito(r.id)),
                      ),
                    ),
                  ),
              if (recent.isNotEmpty) ...[
                SectionTitle(l.recentRemitos),
                for (final r in recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text('${l.remitoType(r.type)} ${r.displayNumber}'),
                        subtitle: Text(l.remitoStatus(r.status)),
                        trailing: r.hasPendingChange
                            ? StatusChip(l.pendingSync, color: AppColors.primary)
                            : null,
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
