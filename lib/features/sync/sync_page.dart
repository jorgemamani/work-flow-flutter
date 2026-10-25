import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/outbox/outbox_op.dart';
import '../../core/outbox/outbox_store.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../core/sync/sync_engine.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/connection_strip.dart';
import '../../shared/widgets/field_scaffold.dart';

/// Estado de sincronización: pendientes en orden, fallidos con su motivo
/// (RN-25), modo sin conexión y "sincronizar ahora".
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final outbox = sl<OutboxStore>();
    return BlocBuilder<SyncCoordinator, SyncStatus>(
      builder: (context, s) {
        final coordinator = context.read<SyncCoordinator>();
        return FutureBuilder<List<OutboxOp>>(
          // Se vuelve a leer cada vez que cambia el estado (contadores incluidos).
          key: ValueKey(Object.hash(s.counts, s.syncing)),
          future: outbox.list(),
          builder: (context, snap) {
            final ops = snap.data ?? const <OutboxOp>[];
            final pending = [for (final o in ops) if (o.status == OutboxStatus.pending) o];
            final failed = [for (final o in ops) if (o.status != OutboxStatus.pending) o];
            return FieldScaffold(
              title: l.syncPendingTitle,
              subtitle: Text([
                s.lastSyncAt == null ? l.neverSynced : l.lastSync(timeAgo(context, s.lastSyncAt!)),
                if (!s.online) l.retriesAlone,
              ].join(' · ')),
              gap: 22,
              footer: FieldFooter(
                children: [
                  AppButton(
                    key: const Key('syncNow'),
                    label: s.syncing ? l.syncing : l.syncNow,
                    isLoading: s.syncing,
                    onPressed: !s.online || s.syncing ? null : coordinator.syncNow,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                    ),
                    onPressed: !s.online
                        ? null
                        : () async {
                            await sl<SyncEngine>().reset();
                            await coordinator.syncNow();
                          },
                    child: Text(l.redownloadAll),
                  ),
                ],
              ),
              children: [
                if (s.sessionExpired)
                  FieldNotice(
                    icon: Icons.lock_clock_outlined,
                    iconColor: AppColors.statusError,
                    child: Text(l.sessionExpiredKeepQueue),
                  ),
                if (s.lastError != null && s.lastError != 'offline')
                  FieldNotice(
                    icon: Icons.error_outline,
                    iconColor: AppColors.statusError,
                    child: Text(s.lastError!),
                  ),
                if (failed.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: StatusChip(l.failedTitle(failed.length), color: AppColors.statusError, fontSize: 16),
                      ),
                      RuledList(children: [for (final o in failed) _FailedTile(op: o)]),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.pendingTitle(pending.length), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSizes.sm),
                    RuledList(
                      children: [
                        if (pending.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(l.nothingPending, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                          ),
                        for (final (i, o) in pending.indexed)
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text('${i + 1}', style: AppFonts.monoStyle(fontSize: 14, color: AppColors.textSecondary)),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.outboxLabel(o.label),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            DateFormat('dd/MM HH:mm').format(o.occurredAt.toLocal()),
                                            if (o.attempts > 0) l.attempts(o.attempts),
                                            if (o.lastError != null) l.outboxError(o.lastError),
                                          ].join(' · '),
                                          style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (o.kind == OutboxKind.attachment)
                                    const Icon(Icons.photo_outlined, size: 20, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.workOffline, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(l.workOfflineHelp,
                                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Switch(
                          key: const Key('offlineSwitch'),
                          value: s.simulatedOffline,
                          onChanged: coordinator.setSimulatedOffline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FailedTile extends StatelessWidget {
  const _FailedTile({required this.op});

  final OutboxOp op;

  /// Alta rechazada porque el código interno ya existe en la empresa.
  static bool _isDuplicateCode(OutboxOp op) =>
      op.label.key == 'opCreateAsset' && op.errorStatus == 409;

  /// Pide otro código y reintenta el alta con el mismo id (y sus fotos).
  Future<void> _fixCode(BuildContext context) async {
    final l = context.l10n;
    final controller = TextEditingController(text: op.body?['internalCode'] as String? ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.fixCodeTitle),
        content: TextField(
          key: const Key('fixCodeField'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.internalCode),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(
            key: const Key('fixCodeSave'),
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: Text(l.retry),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
    if (await sl<FieldRepository>().internalCodeInUse(code, exceptId: op.id)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.codeAlreadyUsed(code))));
      }
      return;
    }
    final (body, patches, label) = FieldActions.withNewInternalCode(op, code);
    await sl<OutboxStore>().retry(op.seq!, body: body, patches: patches, label: label);
    sl<SyncCoordinator>().kick();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final discarded = op.status == OutboxStatus.discarded;
    final color = discarded ? AppColors.statusWarning : AppColors.statusError;
    final actionStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppSizes.buttonHeightSm),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final primary = _isDuplicateCode(op)
        ? OutlinedButton(
            key: const Key('fixCode'),
            style: actionStyle,
            onPressed: () => _fixCode(context),
            child: Text(l.fixCode),
          )
        : discarded
            ? null
            : OutlinedButton(
                style: actionStyle,
                onPressed: () async {
                  await sl<OutboxStore>().retry(op.seq!);
                  sl<SyncCoordinator>().kick();
                },
                child: Text(l.retry),
              );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.outboxLabel(op.label), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(l.outboxError(op.lastError), style: TextStyle(fontSize: 15, height: 1.4, color: color)),
          const SizedBox(height: 3),
          Text(
            [
              DateFormat('dd/MM HH:mm').format(op.occurredAt.toLocal()),
              if (op.attempts > 0) l.attempts(op.attempts),
              if (op.errorStatus != null) 'HTTP ${op.errorStatus}',
            ].join(' · '),
            style: AppFonts.monoStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (primary != null) ...[Expanded(child: primary), const SizedBox(width: 8)],
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.buttonHeightSm),
                    foregroundColor: discarded ? AppColors.ink : AppColors.statusError,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => sl<OutboxStore>().dismiss(op.seq!),
                  child: Text(discarded ? l.understood : l.discard),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
