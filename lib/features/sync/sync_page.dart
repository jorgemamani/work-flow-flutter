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
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/connection_strip.dart';

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
        return Scaffold(
          appBar: AppBar(title: Text(l.syncTitle)),
          body: FutureBuilder<List<OutboxOp>>(
            // Se vuelve a leer cada vez que cambia el estado (contadores incluidos).
            key: ValueKey(Object.hash(s.counts, s.syncing)),
            future: outbox.list(),
            builder: (context, snap) {
              final ops = snap.data ?? const <OutboxOp>[];
              final pending = [for (final o in ops) if (o.status == OutboxStatus.pending) o];
              final failed = [for (final o in ops) if (o.status != OutboxStatus.pending) o];
              return ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(s.online ? Icons.wifi : Icons.wifi_off,
                              color: s.online ? AppColors.statusSuccess : AppColors.statusWarning),
                          title: Text(s.online ? l.online : l.offline),
                          subtitle: Text(s.lastSyncAt == null
                              ? l.neverSynced
                              : l.lastSync(timeAgo(context, s.lastSyncAt!))),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          key: const Key('offlineSwitch'),
                          secondary: const Icon(Icons.airplanemode_active),
                          title: Text(l.workOffline),
                          subtitle: Text(l.workOfflineHelp),
                          value: s.simulatedOffline,
                          onChanged: coordinator.setSimulatedOffline,
                        ),
                        if (s.sessionExpired)
                          ListTile(
                            leading: const Icon(Icons.lock_clock, color: AppColors.statusError),
                            title: Text(l.sessionExpiredKeepQueue),
                          ),
                        if (s.lastError != null && s.lastError != 'offline')
                          ListTile(
                            leading: const Icon(Icons.error_outline, color: AppColors.statusError),
                            title: Text(s.lastError!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  FilledButton.icon(
                    key: const Key('syncNow'),
                    onPressed: !s.online || s.syncing ? null : coordinator.syncNow,
                    icon: s.syncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(s.syncing ? l.syncing : l.syncNow),
                  ),
                  if (failed.isNotEmpty) ...[
                    SectionTitle(l.failedTitle(failed.length)),
                    for (final o in failed) _FailedTile(op: o),
                  ],
                  SectionTitle(l.pendingTitle(pending.length)),
                  if (pending.isEmpty)
                    EmptyState(icon: Icons.cloud_done_outlined, text: l.nothingPending)
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final o in pending)
                            ListTile(
                              dense: true,
                              leading: Icon(o.kind == OutboxKind.attachment ? Icons.photo_outlined : Icons.schedule),
                              title: Text(l.outboxLabel(o.label)),
                              subtitle: Text([
                                DateFormat.yMMMd().add_Hm().format(o.occurredAt.toLocal()),
                                if (o.attempts > 0) l.attempts(o.attempts),
                                if (o.lastError != null) l.outboxError(o.lastError),
                              ].join(' · ')),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSizes.lg),
                  TextButton(
                    onPressed: !s.online
                        ? null
                        : () async {
                            await sl<SyncEngine>().reset();
                            await coordinator.syncNow();
                          },
                    child: Text(l.redownloadAll),
                  ),
                ],
              );
            },
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(discarded ? Icons.info_outline : Icons.error_outline, color: color),
                title: Text(l.outboxLabel(op.label)),
                subtitle: Text(
                  [
                    DateFormat.yMMMd().add_Hm().format(op.occurredAt.toLocal()),
                    if (op.errorStatus != null) 'HTTP ${op.errorStatus}',
                  ].join(' · '),
                ),
              ),
              Text(l.outboxError(op.lastError), style: TextStyle(color: color)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isDuplicateCode(op))
                    TextButton(
                      key: const Key('fixCode'),
                      onPressed: () => _fixCode(context),
                      child: Text(l.fixCode),
                    )
                  else if (!discarded)
                    TextButton(
                      onPressed: () async {
                        await sl<OutboxStore>().retry(op.seq!);
                        sl<SyncCoordinator>().kick();
                      },
                      child: Text(l.retry),
                    ),
                  TextButton(
                    onPressed: () => sl<OutboxStore>().dismiss(op.seq!),
                    child: Text(discarded ? l.understood : l.discard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
