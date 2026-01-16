import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class SalesDB {
  static const String tableName = 'sales';

  // Create the sales table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_no TEXT,
        date TEXT,
        customer_name TEXT, 
        total_amount REAL,
        payment_status TEXT,
        payment_method TEXT,
        remarks TEXT
      )
    ''');
  }

  // Update the insertSale method to properly handle tax data
  static Future<int> insertSale(
    Map<String, dynamic> sale,
    String tempTag,
  ) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      // Insert the sale
      final salesId = await txn.insert(tableName, sale);

      // First get all existing items with complete tax data
      final existingItems = await txn.query(
        'sales_item',
        where: 'temp_tag = ? AND sales_id IS NULL',
        whereArgs: [tempTag],
      );

      // Update items with sales_id while preserving all fields
      for (final item in existingItems) {
        await txn.update(
          'sales_item',
          {
            'sales_id': salesId,
            'temp_tag': null, // Clear temp tag
            // Explicitly preserve all tax-related fields
            'tax_percent': item['tax_percent'],
            'tax_value': item['tax_value'],
            'discount_percent': item['discount_percent'],
            'discount_value': item['discount_value'],
            'subtotal': item['subtotal'],
            'total_amount': item['total_amount'],
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }

      return salesId;
    });
  }

  // Get all sales
  static Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single sale by id
  static Future<Map<String, dynamic>?> getSaleById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // Update a sale
  static Future<int> updateSale(Map<String, dynamic> sale) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      sale,
      where: 'id = ?',
      whereArgs: [sale['id']],
    );
  }

  // Delete a sale with stock adjustment
  static Future<int> deleteSale(int salesId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      final items = await txn.query(
        'sales_item',
        where: 'sales_id = ?',
        whereArgs: [salesId],
      );

      final salesDeleteResult = await txn.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [salesId],
      );

      if (salesDeleteResult == 1 && items.isNotEmpty) {
        for (final item in items) {
          await _adjustStockAfterDeletion(
            txn,
            item['item_name'].toString(),
            int.parse(item['quantity'].toString()),
          );
        }
      }

      await txn.delete(
        'sales_item',
        where: 'sales_id = ?',
        whereArgs: [salesId],
      );

      return salesDeleteResult;
    });
  }

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
      final newStock = currentStock + quantity;

      await txn.update(
        'products',
        {'stockQuantity': newStock},
        where: 'id = ?',
        whereArgs: [product['id']],
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getInvoicesByCustomer(
    int customerId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }
}
