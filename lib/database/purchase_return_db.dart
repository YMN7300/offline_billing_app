import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class PurchaseReturnDB {
  static const String tableName = 'purchase_return';

  // Create the purchase_return table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_no TEXT,
        date TEXT,
        original_purchase_id INTEGER,
        original_purchase_no TEXT,
        supplier_name TEXT, 
        total_amount REAL,
        payment_status TEXT,
        payment_method TEXT,
        remarks TEXT,
        FOREIGN KEY (original_purchase_id) REFERENCES purchase(id)
      )
    ''');
  }

  // Insert a new purchase return
  static Future<int> insertReturn(Map<String, dynamic> returnData) async {
    final db = await DatabaseHelper.instance.database;
    return await db.transaction((txn) async {
      // Insert the return
      final returnId = await txn.insert(tableName, returnData);

      return returnId;
    });
  }

  // Get all returns
  static Future<List<Map<String, dynamic>>> getAllReturns() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single return by id
  static Future<Map<String, dynamic>?> getReturnById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // Update a return
  static Future<int> updateReturn(Map<String, dynamic> returnData) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      returnData,
      where: 'id = ?',
      whereArgs: [returnData['id']],
    );
  }

  // Delete a return with stock adjustment
  static Future<int> deleteReturn(int returnId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      // First get all return items
      final items = await txn.query(
        'purchase_return_item',
        where: 'return_id = ?',
        whereArgs: [returnId],
      );

      // Delete the return
      final returnDeleteResult = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [returnId],
      );

      if (returnDeleteResult == 1 && items.isNotEmpty) {
        // Adjust stock for each item (increase since we're undoing a return)
        for (final item in items) {
          await _adjustStockAfterDeletion(
            txn,
            item['item_name'].toString(),
            int.parse(item['quantity'].toString()),
          );
        }
      }

      // Delete all associated return items
      await txn.delete(
        'purchase_return_item',
        where: 'return_id = ?',
        whereArgs: [returnId],
      );

      return returnDeleteResult;
    });
  }

  // Helper method to adjust stock after return deletion
  static Future<void> _adjustStockAfterDeletion(
    Transaction txn,
    String productName,
    int quantity,
  ) async {
    final products = await txn.query(
      'products',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [productName],
    );

    if (products.isNotEmpty) {
      final product = products.first;
      final currentStock = product['stockQuantity'] as int;
      final newStock =
          currentStock + quantity; // Increase stock (opposite of return)

      await txn.update(
        'products',
        {'stockQuantity': newStock},
        where: 'id = ?',
        whereArgs: [product['id']],
      );
    }
  }

  // Get returns by original purchase ID
  static Future<List<Map<String, dynamic>>> getReturnsByOriginalPurchaseId(
    int purchaseId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'original_purchase_id = ?',
      whereArgs: [purchaseId],
      orderBy: 'date DESC',
    );
  }
}
