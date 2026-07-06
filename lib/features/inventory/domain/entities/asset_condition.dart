enum AssetCondition {
  good,    // Bueno
  regular, // Regular
  bad,     // Malo / Roto
}

extension AssetConditionX on AssetCondition {
  String get displayName {
    switch (this) {
      case AssetCondition.good:
        return 'Bueno';
      case AssetCondition.regular:
        return 'Regular';
      case AssetCondition.bad:
        return 'Malo / Roto';
    }
  }
}
