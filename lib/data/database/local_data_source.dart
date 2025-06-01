import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:pos/data/models/item_model.dart';

class LocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveItems(List<Item> items) async {
    final db = await _dbHelper.database;
    for (var item in items) {
      await db.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Item>> fetchItems() async {
    final db = await _dbHelper.database;
    final result = await db.query('items');
    return result.map((data) => Item.fromMap(data)).toList();
  }

  Future<void> clearItems() async {
    final db = await _dbHelper.database;
    await db.delete('items');
  }
}
