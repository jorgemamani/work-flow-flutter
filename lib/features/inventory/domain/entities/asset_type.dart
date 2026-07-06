enum AssetType {
  vehicle,    // Vehículo
  tool,       // Herramienta
  toolBox,    // Caja/contenedor de herramientas (con sub-ítems)
  epp,        // EPP – Elementos de Protección Personal
  cable,      // Cable / accesorio eléctrico
  consumable, // Consumible (pilas, papelería, etc.)
}

extension AssetTypeX on AssetType {
  String get label {
    switch (this) {
      case AssetType.vehicle:
        return 'Vehículo';
      case AssetType.tool:
        return 'Herramienta';
      case AssetType.toolBox:
        return 'Caja de herramientas';
      case AssetType.epp:
        return 'EPP';
      case AssetType.cable:
        return 'Cable / Accesorio';
      case AssetType.consumable:
        return 'Consumible';
    }
  }

  String get icon {
    switch (this) {
      case AssetType.vehicle:
        return '🚗';
      case AssetType.tool:
        return '🔧';
      case AssetType.toolBox:
        return '🧰';
      case AssetType.epp:
        return '🦺';
      case AssetType.cable:
        return '🔌';
      case AssetType.consumable:
        return '📦';
    }
  }
}
