import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';

/// Todo lo necesario para mostrar ítems: catálogos y la cadena de portadores.
class ItemContext {
  ItemContext({
    required this.assets,
    required this.models,
    required this.brands,
    required this.locations,
    required this.employees,
    required this.conditions,
  }) : resolver = HolderResolver(
          assets: assets,
          locations: locations,
          employees: employees,
          models: models,
        );

  final Map<String, Asset> assets;
  final Map<String, AssetModel> models;
  final Map<String, Brand> brands;
  final Map<String, Location> locations;
  final Map<String, Employee> employees;
  final List<AssetCondition> conditions;
  final HolderResolver resolver;

  static Future<ItemContext> load() async {
    final repo = sl<FieldRepository>();
    return ItemContext(
      assets: await repo.assetsById(),
      models: await repo.models(),
      brands: await repo.brands(),
      locations: await repo.locations(),
      employees: await repo.employees(),
      conditions: await repo.conditions(),
    );
  }

  String modelName(Asset a) => models[a.modelId]?.name ?? '';

  String? conditionName(String? id) {
    if (id == null) return null;
    for (final c in conditions) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  /// "Almacén 4 › Caja CJ-001"
  String where(Asset a, {required String inTransit, required String withPerson}) {
    final parts = resolver.chain(a);
    if (parts.isEmpty) return '';
    return parts.map((p) {
      if (p.type == HolderTypes.inTransit) return inTransit;
      if (p.type == HolderTypes.employee) return '$withPerson ${p.name}'.trim();
      return p.name;
    }).join(' › ');
  }

  /// Contenido de un contenedor (lo que tiene a [a] como portador).
  List<Asset> contents(Asset a) => [
        for (final x in assets.values)
          if (x.holderType == HolderTypes.asset && x.holderId == a.id) x,
      ];
}

/// Fuentes que afectan las pantallas de ítems.
const itemSources = {
  'assets',
  'asset_models',
  'brands',
  'locations',
  'employees',
  'asset_conditions',
  'stock_balances',
};

/// Qué puede hacer la persona con un ítem (solo UX: la API valida siempre).
class ItemAbilities {
  const ItemAbilities({required this.canMove, required this.canChangeStatus});

  final bool canMove;
  final bool canChangeStatus;

  factory ItemAbilities.of(Asset a, {required Profile profile, required String? projectId}) {
    final inProject = a.effectiveProjectId != null && a.effectiveProjectId == projectId;
    final mineOrProject =
        inProject || (a.holderType == HolderTypes.employee && a.holderId == profile.employeeId);
    return ItemAbilities(
      canMove: mineOrProject &&
          a.holderType != HolderTypes.inTransit &&
          a.openRemitoId == null &&
          profile.can(Perms.moveWithinProject, projectId: projectId),
      // La API exige inventory.move para cambiar estado o condición.
      canChangeStatus: mineOrProject && profile.can(Perms.inventoryMove, projectId: projectId),
    );
  }
}
