import 'package:pos/data/api/api_service.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/data/database/database_page_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class ItemRepository {
  final ApiService _apiService;
  final DatabasePageHelper _dbHelper;

  ItemRepository(this._apiService, this._dbHelper);

  /// Get items from local database or API
  Future<List<Item>> getItems({required int limit, required int offset}) async {
    try {
      // Cek apakah masih ada data lokal yang bisa digunakan
      int localItemCount = await getLocalItemCount();

      if (localItemCount > offset) {
        // Gunakan fungsi helper yang sudah ada di DatabasePageHelper
        final localData = await _dbHelper.getItemsByCondition(
            "1=1 ORDER BY id ASC LIMIT ? OFFSET ?", [limit, offset]);

        return localData.map((item) => Item.fromMap(item)).toList();
      }

      // Jika tidak ada data lokal, baru fetch dari API
      final apiData = await _retry(() => _apiService.fetchItems(limit, offset));
      final items = await _parseItemsInBackground(apiData);

      // Simpan ke database lokal hanya jika datanya baru
      if (items.isNotEmpty) {
        await _cacheItems(items);
      }

      return items;
    } catch (e) {
      debugPrint('Error in getItems: $e');
      throw Exception('Failed to get items: $e');
    }
  }

  /// Fetch items directly from API with retry
  Future<List<Item>> fetchItemsFromApi({
    required int limit,
    required int offset,
  }) async {
    try {
      final apiData = await _retry(
        () => _apiService.fetchItems(limit, offset),
      );

      final items = await _parseItemsInBackground(apiData);

      await _cacheItems(items);

      return items;
    } catch (e) {
      throw Exception('Failed to fetch items from API: $e');
    }
  }

  /// Cache items into local database using transaction
  Future<void> _cacheItems(List<Item> items) async {
    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        for (var item in items) {
          await txn.insert(
            'items',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to cache items: $e');
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    final db = await _dbHelper.database;

    try {
      await db.delete('items');
    } catch (e) {
      throw Exception('Failed to clear local data: $e');
    }
  }

  /// Get count of local items
  Future<int> getLocalItemCount() async {
    final db = await _dbHelper.database;

    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM items');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch total items count from API
  Future<int> fetchTotalItemsCount() async {
    try {
      return await _retry(() => _apiService.fetchTotalItemsCount());
    } catch (e) {
      throw Exception('Failed to fetch total items count: $e');
    }
  }

  /// Fetch items with progress callback (batch loading)
  Future<void> fetchItemsWithProgress({
    required int totalItems,
    required int batchSize,
    required Function(int) onProgressUpdate,
  }) async {
    int fetchedItems = await getLocalItemCount();

    try {
      while (fetchedItems < totalItems) {
        final limit = (fetchedItems + batchSize > totalItems)
            ? totalItems - fetchedItems
            : batchSize;

        final apiData = await _retry(
          () => _apiService.fetchItems(limit, fetchedItems),
        );

        final items = await _parseItemsInBackground(apiData);

        await _cacheItems(items);

        fetchedItems += items.length;
        onProgressUpdate(fetchedItems);
      }
    } catch (e) {
      throw Exception('Failed to fetch items with progress: $e');
    }
  }

  /// Retry wrapper untuk handle unstable network
  Future<T> _retry<T>(
    Future<T> Function() task, {
    int retries = 3,
    Duration delay = const Duration(seconds: 10),
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        return await task();
      } catch (e) {
        if (attempt == retries - 1) {
          throw Exception('Max retries reached. Last error: $e');
        }
        await Future.delayed(delay);
      }
    }
    throw Exception('Unreachable code in _retry');
  }

  /// JSON parsing di background isolate
  Future<List<Item>> _parseItemsInBackground(List<dynamic> apiData) async {
    return compute(_parseItems, apiData);
  }

  /// Function buat isolate parsing
  static List<Item> _parseItems(List<dynamic> apiData) {
    return apiData.map<Item>((item) => Item.fromJson(item)).toList();
  }

  /// Check if all items are loaded
  Future<bool> isFullyLoaded() async {
    try {
      final totalItems = await fetchTotalItemsCount(); // Total items from API
      final localItemCount =
          await getLocalItemCount(); // Total items in local database

      return localItemCount >= totalItems;
    } catch (e) {
      debugPrint("Error in isFullyLoaded: $e");
      return false; // Return false jika terjadi error
    }
  }

  // Get items from local database
  Future<List<Item>> getLocalItems({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        limit: limit,
        offset: offset, // Menentukan dari item ke berapa data diambil
      );

      return maps.map((item) => Item.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error getting local items: $e');
      return [];
    }
  }

  // Save items to local database
  Future<void> saveItemsToLocal(List<Item> items) async {
    try {
      final db = await _dbHelper.database;

      // Use a transaction for better performance with multiple inserts
      await db.transaction((txn) async {
        for (var item in items) {
          // Use insert or replace to update existing items
          await txn.insert(
            'items',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      debugPrint('Error saving items to local: $e');
    }
  }
}
