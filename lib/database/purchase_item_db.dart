import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class PurchaseItemDB {
  static const String tableName = 'purchase_item';

  // Create the item table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temp_tag TEXT,      
        purchase_id INTEGER,
        item_name TEXT,
        unit TEXT,
        quantity INTEGER,
        rate REAL,
        subtotal REAL,
        discount_percent REAL,
        discount_value REAL,
        tax_percent REAL,
        tax_value REAL,
        total_amount REAL,
        FOREIGN KEY (purchase_id) REFERENCES purchase(id) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a new item
  static Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, item);
  }

  // Get items by purchase_id
  static Future<List<Map<String, dynamic>>> getItemsByPurchaseId(
    int purchaseId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  // Get items by temp_tag
  static Future<List<Map<String, dynamic>>> getItemsByTempTag(
    String tempTag,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'temp_tag = ?',
      whereArgs: [tempTag],
    );
  }

  // Get a single item by id
  static Future<Map<String, dynamic>?> getItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update the updateItem method to ensure tax data preservation
  static Future<int> updateItem(Map<String, dynamic> item) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure tax_percent is properly formatted if it exists
    if (item['tax_percent'] != null && !item['tax_percent'].contains('%')) {
      item['tax_percent'] = 'GST@ ${item['tax_percent']}%';
    }

    return await db.update(
      tableName,
      {
        // Preserve all existing data
        'item_name': item['item_name'],
        'unit': item['unit'],
        'quantity': item['quantity'],
        'rate': item['rate'],
        // Ensure these fields are never null
        'subtotal': item['subtotal'] ?? 0,
        'discount_percent': item['discount_percent'] ?? 0,
        'discount_value': item['discount_value'] ?? 0,
        'tax_percent': item['tax_percent'] ?? 'GST@ 0%',
        'tax_value': item['tax_value'] ?? 0,
        'total_amount': item['total_amount'] ?? 0,
      },
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  // Add this new method to get complete item data by ID
  static Future<Map<String, dynamic>> getCompleteItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) throw Exception('Item not found');

    return {
      'id': result.first['id'],
      'item_name': result.first['item_name'],
      'unit': result.first['unit'],
      'quantity': result.first['quantity'],
      'rate': result.first['rate'],
      'subtotal': result.first['subtotal'],
      'discount_percent': result.first['discount_percent'],
      'discount_value': result.first['discount_value'],
      'tax_percent': result.first['tax_percent'] ?? 'GST@ 0%',
      'tax_value': result.first['tax_value'],
      'total_amount': result.first['total_amount'],
    };
  }

  // Update items by temp_tag (used when purchase is saved)
  static Future<int> updateItemsWithPurchaseId(
    String tempTag,
    int purchaseId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.transaction((txn) async {
      // First update items with the purchase_id
      final updateCount = await txn.update(
        tableName,
        {
          'purchase_id': purchaseId,
          'temp_tag': null, // Clear temp tag
        },
        where: 'temp_tag = ? AND purchase_id IS NULL',
        whereArgs: [tempTag],
      );

      // Then delete any remaining items with this temp_tag (shouldn't be any)
      await txn.delete(
        tableName,
        where: 'temp_tag = ? AND purchase_id IS NULL',
        whereArgs: [tempTag],
      );

      return updateCount;
    });
  }

  // Clean up all temporary items for a specific purchase
  static Future<int> cleanupTemporaryItemsForPurchase(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'purchase_id = ? AND temp_tag IS NOT NULL',
      whereArgs: [purchaseId],
    );
  }

  // Delete items by purchase_id
  static Future<int> deleteItemsByPurchaseId(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  // Delete item by ID
  static Future<int> deleteItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Delete item by temp_tag
  static Future<int> deleteItemByTempTag(String tempTag) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'temp_tag = ?',
      whereArgs: [tempTag],
    );
  }

  // Delete all temporary items (with null purchase_id)
  static Future<int> deleteAllTemporaryItems() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'purchase_id IS NULL');
  }
}
