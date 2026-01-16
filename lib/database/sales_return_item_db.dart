import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class SalesReturnItemDB {
  static const String tableName = 'sales_return_item';

  // Create the sales_return_item table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id INTEGER,
        original_item_id INTEGER,
        item_name TEXT,
        unit TEXT,
        quantity INTEGER,
        original_quantity INTEGER,
        rate REAL,
        subtotal REAL,
        discount_percent REAL,
        discount_value REAL,
        tax_percent TEXT,
        tax_value REAL,
        total_amount REAL,
        FOREIGN KEY (return_id) REFERENCES sales_return(id) ON DELETE CASCADE,
        FOREIGN KEY (original_item_id) REFERENCES sales_item(id)
      )
    ''');
  }

  // Insert a new sales return item
  static Future<int> insertReturnItem(Map<String, dynamic> returnItem) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, returnItem);
  }

  // Get return items by return_id
  static Future<List<Map<String, dynamic>>> getReturnItemsByReturnId(
    int returnId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'return_id = ?',
      whereArgs: [returnId],
    );
  }

  // Get a single return item by id
  static Future<Map<String, dynamic>?> getReturnItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Get complete return item data by ID
  static Future<Map<String, dynamic>> getCompleteReturnItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) throw Exception('Return item not found');

    return {
      'id': result.first['id'],
      'return_id': result.first['return_id'],
      'original_item_id': result.first['original_item_id'],
      'item_name': result.first['item_name'],
      'unit': result.first['unit'],
      'quantity': result.first['quantity'],
      'original_quantity': result.first['original_quantity'],
      'rate': result.first['rate'],
      'subtotal': result.first['subtotal'],
      'discount_percent': result.first['discount_percent'],
      'discount_value': result.first['discount_value'],
      'tax_percent': result.first['tax_percent'] ?? 'GST@ 0%',
      'tax_value': result.first['tax_value'],
      'total_amount': result.first['total_amount'],
    };
  }

  // Update a return item
  static Future<int> updateReturnItem(Map<String, dynamic> returnItem) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure tax_percent is properly formatted if it exists
    if (returnItem['tax_percent'] != null &&
        !returnItem['tax_percent'].contains('%')) {
      returnItem['tax_percent'] = 'GST@ ${returnItem['tax_percent']}%';
    }

    return await db.update(
      tableName,
      {
        'item_name': returnItem['item_name'],
        'unit': returnItem['unit'],
        'quantity': returnItem['quantity'],
        'rate': returnItem['rate'],
        'subtotal': returnItem['subtotal'] ?? 0,
        'discount_percent': returnItem['discount_percent'] ?? 0,
        'discount_value': returnItem['discount_value'] ?? 0,
        'tax_percent': returnItem['tax_percent'] ?? 'GST@ 0%',
        'tax_value': returnItem['tax_value'] ?? 0,
        'total_amount': returnItem['total_amount'] ?? 0,
      },
      where: 'id = ?',
      whereArgs: [returnItem['id']],
    );
  }

  // Delete a return item by ID
  static Future<int> deleteReturnItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Delete all return items for a return
  static Future<int> deleteReturnItemsByReturnId(int returnId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      tableName,
      where: 'return_id = ?',
      whereArgs: [returnId],
    );
  }

  // Get return items by original item ID
  static Future<List<Map<String, dynamic>>> getReturnItemsByOriginalItemId(
    int originalItemId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      tableName,
      where: 'original_item_id = ?',
      whereArgs: [originalItemId],
    );
  }
}
