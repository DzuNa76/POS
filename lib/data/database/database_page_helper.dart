import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabasePageHelper {
  static final DatabasePageHelper instance =
      DatabasePageHelper._privateConstructor();
  static Database? _database;

  DatabasePageHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
    } catch (e) {
      throw Exception("Failed to initialize database: $e");
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');

      return await openDatabase(
        path,
        version: 5,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // Misal, hapus database yang corrupt
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');
      await deleteDatabase(path);
      throw Exception(
          "Database initialization failed. Database has been reset: $e");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        owner TEXT,
        creation DATETIME,
        modified DATETIME,
        modified_by TEXT,
        docstatus TINYINT,
        idx INTEGER,
        naming_series TEXT,
        item_code TEXT,
        item_name TEXT,
        item_group TEXT,
        stock_uom TEXT,
        disabled TINYINT,
        allow_alternative_item TINYINT,
        is_stock_item TINYINT,
        has_variants TINYINT,
        opening_stock REAL,
        valuation_rate REAL,
        standard_rate REAL,
        is_fixed_asset TINYINT,
        auto_create_assets TINYINT,
        is_grouped_asset TINYINT,
        asset_category TEXT,
        asset_naming_series TEXT,
        over_delivery_receipt_allowance REAL,
        over_billing_allowance REAL,
        image TEXT,
        description TEXT,
        brand TEXT,
        shelf_life_in_days INTEGER,
        end_of_life DATE,
        default_material_request_type TEXT,
        valuation_method TEXT,
        warranty_period INTEGER,
        weight_per_unit REAL,
        weight_uom TEXT,
        allow_negative_stock TINYINT,
        has_batch_no TINYINT,
        create_new_batch TINYINT,
        batch_number_series TEXT,
        has_expiry_date TINYINT,
        retain_sample TINYINT,
        sample_quantity REAL,
        has_serial_no TINYINT,
        serial_no_series TEXT,
        variant_of TEXT,
        variant_based_on TEXT,
        enable_deferred_expense TINYINT,
        no_of_months_exp INTEGER,
        enable_deferred_revenue TINYINT,
        no_of_months INTEGER,
        purchase_uom TEXT,
        min_order_qty REAL,
        safety_stock REAL,
        is_purchase_item TINYINT,
        lead_time_days INTEGER,
        last_purchase_rate REAL,
        is_customer_provided_item TINYINT,
        customer TEXT,
        delivered_by_supplier TINYINT,
        country_of_origin TEXT,
        customs_tariff_number TEXT,
        sales_uom TEXT,
        grant_commission TINYINT,
        is_sales_item TINYINT,
        max_discount REAL,
        inspection_required_before_purchase TINYINT,
        quality_inspection_template TEXT,
        inspection_required_before_delivery TINYINT,
        include_item_in_manufacturing TINYINT,
        is_sub_contracted_item TINYINT,
        default_bom TEXT,
        customer_code TEXT,
        default_item_manufacturer TEXT,
        default_manufacturer_part_no TEXT,
        total_projected_qty REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Tutup database sebelum menghapus
      await db.close();

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');

      // Hapus database lama
      await deleteDatabase(path);

      // Setel ulang instance agar tidak mengacu pada database yang sudah dihapus
      _database = null;
    }
  }

  Future<bool> isTableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<int> insertItem(Map<String, dynamic> item) async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.insert('items', item);
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to insert item: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.query('items');
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to fetch items: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getItemsByCondition(
      String condition, List<dynamic> args) async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.query('items', where: condition, whereArgs: args);
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to fetch items with condition: $e");
    }
  }

  Future<int> updateItem(
      String itemName, Map<String, dynamic> updatedData) async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.update(
          'items',
          updatedData,
          where: 'name = ?',
          whereArgs: [itemName],
        );
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to update item: $e");
    }
  }

  Future<int> deleteItem(String itemName) async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.delete(
          'items',
          where: 'name = ?',
          whereArgs: [itemName],
        );
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to delete item: $e");
    }
  }

  Future<int> deleteAllItems() async {
    try {
      final db = await database;
      if (await isTableExists('items')) {
        return await db.delete('items');
      } else {
        throw Exception("Table 'items' does not exist!");
      }
    } catch (e) {
      throw Exception("Failed to delete all items: $e");
    }
  }
}
