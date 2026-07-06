import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  static const _dbName = 'workflow.db';
  static const _dbVersion = 1;

  // Table names
  static const tableAssets = 'assets';
  static const tableAssetBrands = 'asset_brands';
  static const tableAssetModels = 'asset_models';
  static const tableAssetSubItems = 'asset_sub_items';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableAssetBrands (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAssetModels (
        id TEXT PRIMARY KEY,
        brand_id TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (brand_id) REFERENCES $tableAssetBrands(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAssets (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        brand_id TEXT,
        brand_name TEXT,
        model_id TEXT,
        model_name TEXT,
        serial_number TEXT,
        color TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        location TEXT,
        condition TEXT NOT NULL DEFAULT 'good',
        observations TEXT,
        photo_paths TEXT NOT NULL DEFAULT '[]',
        license_plate TEXT,
        year INTEGER,
        engine_number TEXT,
        chassis_number TEXT,
        mileage INTEGER,
        vtv_expiry TEXT,
        insurance_expiry TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAssetSubItems (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        description TEXT NOT NULL,
        brand_name TEXT,
        serial_number TEXT,
        color TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        condition TEXT NOT NULL DEFAULT 'good',
        observations TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (asset_id) REFERENCES $tableAssets(id) ON DELETE CASCADE
      )
    ''');

    // Indices
    await db.execute(
      'CREATE INDEX idx_assets_type ON $tableAssets(type)',
    );
    await db.execute(
      'CREATE INDEX idx_assets_condition ON $tableAssets(condition)',
    );
    await db.execute(
      'CREATE INDEX idx_sub_items_asset_id ON $tableAssetSubItems(asset_id)',
    );
    await db.execute(
      'CREATE INDEX idx_models_brand_id ON $tableAssetModels(brand_id)',
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
