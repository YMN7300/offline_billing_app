import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class ProductDB {
  static const String tableName = 'products';

  // Create the products table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        unit TEXT,
        category TEXT,
        brand TEXT,
        salePrice REAL,
        costPrice REAL,
        stockQuantity INTEGER,
        lowStockAlert INTEGER,
        date TEXT
      )
    ''');
  }

  // Insert a new product
  static Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, product);
  }

  // Get all products
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single product by id
  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Update a product
  static Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  // Update product stock
  static Future<int> updateProductStock(
    String productName,
    int quantity,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // Find the product (case insensitive and trimmed)
    final products = await db.query(
      'products',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [productName],
    );

    if (products.isEmpty) {
      return 0;
    }

    final product = products.first;
    final currentStock = product['stockQuantity'] as int;
    final newStock = currentStock + quantity;

    // Perform the update
    return await db.update(
      'products',
      {'stockQuantity': newStock},
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  // Delete a product by id
  static Future<int> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
