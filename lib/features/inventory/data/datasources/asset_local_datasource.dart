import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_brand.dart';
import '../../domain/entities/asset_condition.dart';
import '../../domain/entities/asset_model_entity.dart';
import '../../domain/entities/asset_sub_item.dart';
import '../../domain/entities/asset_type.dart';
import '../database/app_database.dart';
import '../models/asset_brand_db_model.dart';
import '../models/asset_db_model.dart';
import '../models/asset_model_db_model.dart';
import '../models/asset_sub_item_db_model.dart';

abstract class IAssetLocalDataSource {
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    AssetCondition? condition,
    String? location,
  });

  Future<Asset?> getAssetById(String id);
  Future<Asset> createAsset(Asset asset);
  Future<Asset> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);

  Future<List<AssetBrand>> getBrands();
  Future<AssetBrand> createBrand(String name);
  Future<void> deleteBrand(String id);

  Future<List<AssetModelEntity>> getModelsByBrand(String brandId);
  Future<AssetModelEntity> createModel(String brandId, String name);
  Future<void> deleteModel(String id);
}

class AssetLocalDataSource implements IAssetLocalDataSource {
  AssetLocalDataSource(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Assets ────────────────────────────────────────────────────

  @override
  Future<List<Asset>> getAssets({
    String? query,
    AssetType? type,
    AssetCondition? condition,
    String? location,
  }) async {
    final db = await _db.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type.name);
    }
    if (condition != null) {
      whereParts.add('condition = ?');
      whereArgs.add(condition.name);
    }
    if (location != null && location.isNotEmpty) {
      whereParts.add('location LIKE ?');
      whereArgs.add('%$location%');
    }
    if (query != null && query.isNotEmpty) {
      whereParts.add(
        '(description LIKE ? OR brand_name LIKE ? OR model_name LIKE ? OR serial_number LIKE ? OR license_plate LIKE ?)',
      );
      final q = '%$query%';
      whereArgs.addAll([q, q, q, q, q]);
    }

    final rows = await db.query(
      AppDatabase.tableAssets,
      where: whereParts.isNotEmpty ? whereParts.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
    );

    final assets = <Asset>[];
    for (final row in rows) {
      final model = AssetDbModel.fromMap(row);
      final subItems = await _getSubItems(db, model.id);
      assets.add(model.toEntity(subItems: subItems));
    }
    return assets;
  }

  @override
  Future<Asset?> getAssetById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableAssets,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final model = AssetDbModel.fromMap(rows.first);
    final subItems = await _getSubItems(db, id);
    return model.toEntity(subItems: subItems);
  }

  @override
  Future<Asset> createAsset(Asset asset) async {
    final db = await _db.database;
    final now = DateTime.now();
    final newAsset = asset.copyWith(
      id: asset.id.isEmpty ? _uuid.v4() : asset.id,
      createdAt: now,
      updatedAt: now,
    );
    final model = AssetDbModel.fromEntity(newAsset);

    await db.transaction((txn) async {
      await txn.insert(
        AppDatabase.tableAssets,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _upsertSubItems(txn, newAsset.id, newAsset.subItems);
    });

    return newAsset;
  }

  @override
  Future<Asset> updateAsset(Asset asset) async {
    final db = await _db.database;
    final updated = asset.copyWith(updatedAt: DateTime.now());
    final model = AssetDbModel.fromEntity(updated);

    await db.transaction((txn) async {
      await txn.update(
        AppDatabase.tableAssets,
        model.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      // Replace all sub-items
      await txn.delete(
        AppDatabase.tableAssetSubItems,
        where: 'asset_id = ?',
        whereArgs: [updated.id],
      );
      await _upsertSubItems(txn, updated.id, updated.subItems);
    });

    return updated;
  }

  @override
  Future<void> deleteAsset(String id) async {
    final db = await _db.database;
    await db.delete(
      AppDatabase.tableAssets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Brands ────────────────────────────────────────────────────

  @override
  Future<List<AssetBrand>> getBrands() async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableAssetBrands,
      orderBy: 'name ASC',
    );
    return rows
        .map((r) => AssetBrandDbModel.fromMap(r).toEntity())
        .toList();
  }

  @override
  Future<AssetBrand> createBrand(String name) async {
    final db = await _db.database;
    final brand = AssetBrandDbModel(id: _uuid.v4(), name: name.trim());
    await db.insert(
      AppDatabase.tableAssetBrands,
      brand.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return brand.toEntity();
  }

  @override
  Future<void> deleteBrand(String id) async {
    final db = await _db.database;
    await db.delete(
      AppDatabase.tableAssetBrands,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Models ────────────────────────────────────────────────────

  @override
  Future<List<AssetModelEntity>> getModelsByBrand(String brandId) async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableAssetModels,
      where: 'brand_id = ?',
      whereArgs: [brandId],
      orderBy: 'name ASC',
    );
    return rows
        .map((r) => AssetModelDbModel.fromMap(r).toEntity())
        .toList();
  }

  @override
  Future<AssetModelEntity> createModel(String brandId, String name) async {
    final db = await _db.database;
    final model = AssetModelDbModel(
      id: _uuid.v4(),
      brandId: brandId,
      name: name.trim(),
    );
    await db.insert(
      AppDatabase.tableAssetModels,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteModel(String id) async {
    final db = await _db.database;
    await db.delete(
      AppDatabase.tableAssetModels,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<List<AssetSubItem>> _getSubItems(Database db, String assetId) async {
    final rows = await db.query(
      AppDatabase.tableAssetSubItems,
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'sort_order ASC',
    );
    return rows
        .map((r) => AssetSubItemDbModel.fromMap(r).toEntity())
        .toList();
  }

  Future<void> _upsertSubItems(
    DatabaseExecutor txn,
    String assetId,
    List<AssetSubItem> items,
  ) async {
    for (var i = 0; i < items.length; i++) {
      final item = items[i].copyWith(
        id: items[i].id.isEmpty ? _uuid.v4() : items[i].id,
        assetId: assetId,
        sortOrder: i,
      );
      await txn.insert(
        AppDatabase.tableAssetSubItems,
        AssetSubItemDbModel.fromEntity(item).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
