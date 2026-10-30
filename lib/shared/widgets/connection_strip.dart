import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_coordinator.dart';
import '../../features/auth/presentation/session_cubit.dart';
import '../../routing/app_router.dart';
import '../../routing/route_names.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_extensions.dart';

/// Pantallas a pantalla completa (el escáner) que esconden la franja.
final fullScreenDepth = ValueNotifier<int>(0);

/// Envuelve toda la app: con sesión, la franja de conexión queda fija arriba
/// de cada pantalla (v4 §11: "la app muestra siempre cuántas acciones quedan
/// pendientes y avisa si alguna falló").
class ConnectionFrame extends StatelessWidget {
  const ConnectionFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (a, b) => a.phase != b.phase,
      builder: (context, session) => ValueListenableBuilder<int>(
        valueListenable: fullScreenDepth,
        builder: (context, depth, _) {
          final visible = session.phase == SessionPhase.authenticated && depth == 0;
          // Misma estructura siempre: cambiarla rearmaría el navegador.
          return Column(
            children: [
              ConnectionStrip(visible: visible),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: visible,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Franja de 40 px: sin conexión en tinta, con conexión en piedra. Abre
/// Sincronización.
class ConnectionStrip extends StatelessWidget {
  const ConnectionStrip({super.key, this.visible = true});

  final bool visible;

  static void _openSync() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (path != RouteNames.sync) appRouter.push(RouteNames.sync);
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return BlocBuilder<SyncCoordinator, SyncStatus>(
      builder: (context, s) {
        final l = context.l10n;
        final failed = s.counts.failed;
        final pending = s.counts.pending;
        final offline = !s.online;
        final Color dot;
        final String label;
        final String right;
        if (offline) {
          dot = failed > 0 ? AppColors.statusError : AppColors.offlineDot;
          label = l.offline;
          right = failed > 0
              ? l.connWithProblems(failed)
              : (pending > 0 ? l.connSavedNotSent(pending) : l.connAllSavedOnPhone);
        } else if (s.sessionExpired) {
          dot = AppColors.statusError;
          label = l.online;
          right = l.connSessionExpired;
        } else {
          dot = failed > 0 ? AppColors.statusError : AppColors.statusSuccess;
          label = l.online;
          right = failed > 0
              ? l.connWithProblems(failed)
              : (pending > 0 ? l.connSending(pending) : l.allSynced);
        }
        final fg = offline ? Colors.white : AppColors.ink;
        final top = MediaQuery.paddingOf(context).top;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: offline ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Material(
            color: offline ? AppColors.ink : AppColors.backgroundLight,
            child: InkWell(
              key: const Key('syncIndicator'),
              onTap: _openSync,
              child: Container(
                height: AppSizes.connectionStripHeight + top,
                padding: EdgeInsets.fromLTRB(AppSizes.md, top, AppSizes.md, 0),
                decoration: BoxDecoration(
                  border: offline ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14, color: fg),
                        ),
                      ),
                      if (s.syncing && !offline) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
                        ),
                        const SizedBox(width: AppSizes.sm),
                      ],
                      Text(right, style: AppFonts.monoStyle(fontSize: 13, color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String timeAgo(BuildContext context, DateTime t) {
  final l = context.l10n;
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.agoNow;
  if (d.inHours < 1) return l.agoMinutes(d.inMinutes);
  if (d.inDays < 1) return l.agoHours(d.inHours);
  return l.agoDays(d.inDays);
}
