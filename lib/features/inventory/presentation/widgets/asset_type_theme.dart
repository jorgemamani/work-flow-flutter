import 'package:flutter/material.dart';

import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_type.dart';

class AssetTypeTheme {
  AssetTypeTheme._();

  static Color colorFor(AssetType type) {
    switch (type) {
      case AssetType.vehicle:
        return const Color(0xFF6366F1); // indigo
      case AssetType.tool:
        return const Color(0xFFF59E0B); // amber
      case AssetType.toolBox:
        return const Color(0xFF10B981); // emerald
      case AssetType.epp:
        return const Color(0xFFEF4444); // red
      case AssetType.cable:
        return const Color(0xFF3B82F6); // blue
      case AssetType.consumable:
        return const Color(0xFF8B5CF6); // violet
    }
  }

  static IconData iconFor(AssetType type) {
    switch (type) {
      case AssetType.vehicle:
        return Icons.directions_car_rounded;
      case AssetType.tool:
        return Icons.build_rounded;
      case AssetType.toolBox:
        return Icons.cases_rounded;
      case AssetType.epp:
        return Icons.health_and_safety_rounded;
      case AssetType.cable:
        return Icons.cable_rounded;
      case AssetType.consumable:
        return Icons.inventory_2_rounded;
    }
  }

  static Color conditionColor(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.good:
        return const Color(0xFF22C55E);
      case AssetCondition.regular:
        return const Color(0xFFF59E0B);
      case AssetCondition.bad:
        return const Color(0xFFEF4444);
    }
  }
}
