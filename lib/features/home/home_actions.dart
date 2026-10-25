import '../../core/auth/profile.dart';

enum HomeAction {
  scan,
  receiveRemito,
  verification,
  dailyLog,
  incident,
  checkIn,
  newItem,
  requirement,
  returnRemito,
}

/// Qué acciones ve cada uno en el inicio, según sus permisos (no hay "modo
/// campo" ni "modo oficina"). Se agrupan en lo que se hace en el proyecto y
/// lo de logística; si alguien tiene de los dos, el inicio muestra las dos
/// secciones con título.
class HomeActions {
  const HomeActions({required this.project, required this.logistics});

  final List<HomeAction> project;
  final List<HomeAction> logistics;

  bool get showSections => project.isNotEmpty && logistics.isNotEmpty;

  factory HomeActions.of(Profile p, String? projectId) {
    bool can(String perm) => p.can(perm, projectId: projectId);
    final project = <HomeAction>[
      HomeAction.scan,
      if (can(Perms.remitosConfirm)) HomeAction.receiveRemito,
      if (can(Perms.verificationsSubmit)) HomeAction.verification,
      if (can(Perms.submissionsCreate)) HomeAction.dailyLog,
      if (can(Perms.incidentsCreate)) HomeAction.incident,
      if (p.employeeId != null && p.can(Perms.checkinsSelf)) HomeAction.checkIn,
    ];
    final logistics = <HomeAction>[
      if (can(Perms.inventoryWrite)) HomeAction.newItem,
      if (can(Perms.remitosWrite)) HomeAction.returnRemito,
      if (can(Perms.requirementsCreate)) HomeAction.requirement,
    ];
    return HomeActions(project: project, logistics: logistics);
  }
}
