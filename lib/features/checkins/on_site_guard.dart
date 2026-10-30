import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../dependency_injection.dart';
import '../../shared/extensions/context_extensions.dart';
import '../auth/presentation/session_cubit.dart';

/// RN-02: sin permisos de logística, solo confirma remitos o mueve ítems
/// quien trabaja en el proyecto, y la API lo sabe por la marcación de subida
/// (`employee.currentProjectId`). Si todavía no la registró, se ofrece
/// registrarla ahora: entra a la cola ANTES del hecho, así llega primero.
///
/// Devuelve false si el usuario canceló.
Future<bool> ensureOnSite(BuildContext context, {required List<String> bypassPermissions}) async {
  final session = context.read<SessionCubit>();
  final profile = session.state.profile;
  final projectId = session.state.projectId;
  if (profile == null || projectId == null || profile.employeeId == null) return true;
  if (bypassPermissions.any((p) => profile.can(p, projectId: projectId))) return true;
  if (profile.onSite && profile.currentProjectId == projectId) return true;

  final l = context.l10n;
  final project = await sl<FieldRepository>().project(projectId);
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.onSiteRequiredTitle),
      content: Text(l.onSiteRequiredBody(project?.name ?? '')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(
          key: const Key('registerUpAndContinue'),
          onPressed: () => Navigator.pop(c, true),
          child: Text(l.registerUpAndContinue),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await sl<FieldActions>().checkIn(
    projectId: projectId,
    type: 'UP',
    employeeId: profile.employeeId!,
    self: true,
    employeeName: profile.fullName,
  );
  await session.applyLocalProfile(applySelfCheckIn(profile, type: 'UP', projectId: projectId));
  return true;
}
