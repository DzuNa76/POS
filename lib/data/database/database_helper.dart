import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId TEXT,
        customerName TEXT,
        paymentMethod TEXT,
        referralCode TEXT,
        cashierName TEXT,
        transactionDate TEXT,
        subtotal INTEGER,
        tax INTEGER,
        total INTEGER,
        paid INTEGER,
        change INTEGER,
        timestamp INTEGER
      )
    ''');

    // Create order items table with relation to transactions
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId TEXT,
        name TEXT,
        quantity INTEGER,
        price INTEGER,
        FOREIGN KEY (transactionId) REFERENCES transactions (transactionId)
      )
    ''');
  }

  // Insert a transaction record
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction);
  }

  // Insert order items
  Future<int> insertOrderItem(Map<String, dynamic> orderItem) async {
    Database db = await database;
    return await db.insert('order_items', orderItem);
  }

  // Get all transactions
  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC');
  }

  // Get transactions by date range
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    Database db = await database;
    return await db.query(
        'transactions',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.add(const Duration(days: 1)).millisecondsSinceEpoch - 1
        ],
        orderBy: 'timestamp DESC'
    );
  }

  // Search transactions by transactionId
  Future<List<Map<String, dynamic>>> searchTransactionById(String searchTerm) async {
    Database db = await database;
    return await db.query(
        'transactions',
        where: 'transactionId LIKE ?',
        whereArgs: ['%$searchTerm%'],
        orderBy: 'timestamp DESC'
    );
  }

  // Get order items for a specific transaction
  Future<List<Map<String, dynamic>>> getOrderItems(String transactionId) async {
    Database db = await database;
    return await db.query(
        'order_items',
        where: 'transactionId = ?',
        whereArgs: [transactionId]
    );
  }

  // Metode untuk mencari transaksi berdasarkan ID dan rentang tanggal
  Future<List<Map<String, dynamic>>> searchTransactionByIdWithDateRange(
      String searchQuery,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final db = await database;

    // Convert dates to midnight timestamps untuk perbandingan yang tepat
    final startTimestamp = DateTime(
        startDate.year,
        startDate.month,
        startDate.day
    ).millisecondsSinceEpoch;

    // Tanggal akhir harus mencakup seluruh hari
    final endTimestamp = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23, 59, 59, 999
    ).millisecondsSinceEpoch;

    return await db.query(
      'transactions',
      where: 'transactionId LIKE ? AND timestamp BETWEEN ? AND ?',
      whereArgs: ['%$searchQuery%', startTimestamp, endTimestamp],
      orderBy: 'timestamp DESC',
    );
  }

  // Metode untuk mendapatkan transaksi berdasarkan metode pembayaran
  Future<List<Map<String, dynamic>>> getTransactionsByPaymentMethod(String paymentMethod) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'paymentMethod = ?',
      whereArgs: [paymentMethod],
      orderBy: 'timestamp DESC',
    );
  }

// Metode untuk mencari transaksi berdasarkan ID dan metode pembayaran
  Future<List<Map<String, dynamic>>> searchTransactionByIdWithPayment(
      String searchQuery,
      String paymentMethod,
      ) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'transactionId LIKE ? AND paymentMethod = ?',
      whereArgs: ['%$searchQuery%', paymentMethod],
      orderBy: 'timestamp DESC',
    );
  }

// Metode untuk mendapatkan transaksi berdasarkan rentang tanggal dan metode pembayaran
  Future<List<Map<String, dynamic>>> getTransactionsByDateRangeAndPayment(
      DateTime startDate,
      DateTime endDate,
      String paymentMethod,
      ) async {
    final db = await database;

    // Convert dates untuk proper comparison
    final startTimestamp = DateTime(
        startDate.year,
        startDate.month,
        startDate.day
    ).millisecondsSinceEpoch;

    final endTimestamp = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23, 59, 59, 999
    ).millisecondsSinceEpoch;

    return await db.query(
      'transactions',
      where: 'timestamp BETWEEN ? AND ? AND paymentMethod = ?',
      whereArgs: [startTimestamp, endTimestamp, paymentMethod],
      orderBy: 'timestamp DESC',
    );
  }

// Metode untuk mencari transaksi berdasarkan ID, rentang tanggal, dan metode pembayaran
  Future<List<Map<String, dynamic>>> searchTransactionByIdWithDateRangeAndPayment(
      String searchQuery,
      DateTime startDate,
      DateTime endDate,
      String paymentMethod,
      ) async {
    final db = await database;

    // Convert dates untuk proper comparison
    final startTimestamp = DateTime(
        startDate.year,
        startDate.month,
        startDate.day
    ).millisecondsSinceEpoch;

    final endTimestamp = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23, 59, 59, 999
    ).millisecondsSinceEpoch;

    return await db.query(
      'transactions',
      where: 'transactionId LIKE ? AND timestamp BETWEEN ? AND ? AND paymentMethod = ?',
      whereArgs: ['%$searchQuery%', startTimestamp, endTimestamp, paymentMethod],
      orderBy: 'timestamp DESC',
    );
  }

  // Get transaction details
  Future<Map<String, dynamic>?> getTransactionDetails(String transactionId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
        'transactions',
        where: 'transactionId = ?',
        whereArgs: [transactionId],
        limit: 1
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}