import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_coordinator.dart';
import '../../routing/route_names.dart';
import '../constants/app_colors.dart';
import '../extensions/context_extensions.dart';

/// Acción de la barra: conexión + pendientes (v4 §11: "la app muestra
/// siempre cuántas acciones quedan pendientes y avisa si alguna falló").
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCoordinator, SyncStatus>(
      builder: (context, s) {
        final l = context.l10n;
        final failed = s.counts.failed;
        final pending = s.counts.pending;
        final IconData icon;
        final Color color;
        if (!s.online) {
          icon = Icons.cloud_off;
          color = AppColors.statusWarning;
        } else if (s.syncing) {
          icon = Icons.cloud_sync;
          color = AppColors.primary;
        } else if (failed > 0) {
          icon = Icons.cloud_off_outlined;
          color = AppColors.statusError;
        } else {
          icon = pending > 0 ? Icons.cloud_upload : Icons.cloud_done;
          color = pending > 0 ? AppColors.primary : AppColors.statusSuccess;
        }
        final badge = failed > 0 ? failed : pending;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            key: const Key('syncIndicator'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(RouteNames.sync),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: badge > 0,
                    backgroundColor: failed > 0 ? AppColors.statusError : AppColors.primary,
                    label: Text('$badge'),
                    child: Icon(icon, color: color),
                  ),
                  if (!s.online) ...[
                    const SizedBox(width: 6),
                    Text(
                      l.offline,
                      style: context.textTheme.labelMedium?.copyWith(color: color),
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

/// Franja de estado para la pantalla de inicio.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCoordinator, SyncStatus>(
      builder: (context, s) {
        final l = context.l10n;
        final last = s.lastSyncAt;
        final subtitle = [
          if (!s.online) l.offlineWorkingLocally,
          if (last != null) l.lastSync(_ago(context, last)) else l.neverSynced,
        ].join(' · ');
        return Card(
          child: ListTile(
            onTap: () => context.push(RouteNames.sync),
            leading: s.syncing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(s.online ? Icons.cloud_done_outlined : Icons.cloud_off, color: s.online ? AppColors.statusSuccess : AppColors.statusWarning),
            title: Text(
              s.counts.failed > 0
                  ? l.failedCount(s.counts.failed)
                  : (s.counts.pending > 0 ? l.pendingCount(s.counts.pending) : l.allSynced),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: s.counts.failed > 0 ? AppColors.statusError : null,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

String _ago(BuildContext context, DateTime t) {
  final l = context.l10n;
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.agoNow;
  if (d.inHours < 1) return l.agoMinutes(d.inMinutes);
  if (d.inDays < 1) return l.agoHours(d.inHours);
  return l.agoDays(d.inDays);
}

String timeAgo(BuildContext context, DateTime t) => _ago(context, t);
