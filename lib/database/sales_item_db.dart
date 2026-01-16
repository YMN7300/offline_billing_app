import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class SalesItemDB {
  static const String tableName = 'sales_item';

  // Create the sales_item table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temp_tag TEXT,      
        sales_id INTEGER,
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
        FOREIGN KEY (sales_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a new sales item
  static Future<int> insertSalesItem(Map<String, dynamic> salesItem) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, salesItem);
  }

  // Get sales items by sales_id
  static Future<List<Map<String, dynamic>>> getSalesItemsBySalesId(
    int salesId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'sales_id = ?',
      whereArgs: [salesId],
    );
  }

  // Get sales items by temp_tag
  static Future<List<Map<String, dynamic>>> getSalesItemsByTempTag(
    String tempTag,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'temp_tag = ? AND sales_id IS NULL',
      whereArgs: [tempTag],
    );
  }

  // Get a single sales item by id
  static Future<Map<String, dynamic>?> getSalesItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update the updateSalesItem method to ensure tax data preservation
  static Future<int> updateSalesItem(Map<String, dynamic> salesItem) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure tax_percent is properly formatted if it exists
    if (salesItem['tax_percent'] != null &&
        !salesItem['tax_percent'].contains('%')) {
      salesItem['tax_percent'] = 'GST@ ${salesItem['tax_percent']}%';
    }

    return await db.update(
      tableName,
      {
        // Preserve all existing data
        'item_name': salesItem['item_name'],
        'unit': salesItem['unit'],
        'quantity': salesItem['quantity'],
        'rate': salesItem['rate'],
        // Ensure these fields are never null
        'subtotal': salesItem['subtotal'] ?? 0,
        'discount_percent': salesItem['discount_percent'] ?? 0,
        'discount_value': salesItem['discount_value'] ?? 0,
        'tax_percent': salesItem['tax_percent'] ?? 'GST@ 0%',
        'tax_value': salesItem['tax_value'] ?? 0,
        'total_amount': salesItem['total_amount'] ?? 0,
      },
      where: 'id = ?',
      whereArgs: [salesItem['id']],
    );
  }

  // Add this new method to get complete item data by ID
  static Future<Map<String, dynamic>> getCompleteSalesItemById(int id) async {
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

  // Update sales items by temp_tag (used when sales is saved)
  static Future<int> updateSalesItemsWithSalesId(
    String tempTag,
    int salesId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.transaction((txn) async {
      // First update items with the sales_id
      final updateCount = await txn.update(
        tableName,
        {
          'sales_id': salesId,
          'temp_tag': null, // Clear temp tag
        },
        where: 'temp_tag = ? AND sales_id IS NULL',
        whereArgs: [tempTag],
      );

      // Then delete any remaining items with this temp_tag (shouldn't be any)
      await txn.delete(
        tableName,
        where: 'temp_tag = ? AND sales_id IS NULL',
        whereArgs: [tempTag],
      );

      return updateCount;
    });
  }

  // Delete sales items by sales_id
  static Future<int> deleteSalesItemsBySalesId(int salesId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'sales_id = ?',
      whereArgs: [salesId],
    );
  }

  // Delete sales item by ID
  static Future<int> deleteSalesItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Delete sales item by temp_tag
  static Future<int> deleteSalesItemByTempTag(String tempTag) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'temp_tag = ? AND sales_id IS NULL',
      whereArgs: [tempTag],
    );
  }

  // Delete all temporary sales items (with null sales_id)
  static Future<int> deleteAllTemporarySalesItems() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'sales_id IS NULL');
  }
}
