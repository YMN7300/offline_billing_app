import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class PurchaseDB {
  static const String tableName = 'purchase';

  // Create the purchase table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_no TEXT,
        date TEXT,
        vendor_name TEXT, 
        total_amount REAL,
        payment_status TEXT,
        payment_method TEXT,
        remarks TEXT
      )
    ''');
  }

  // Update the insertPurchase method to properly handle tax data
  static Future<int> insertPurchase(
    Map<String, dynamic> purchase,
    String tempTag,
  ) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      // Insert the purchase
      final purchaseId = await txn.insert(tableName, purchase);

      // First get all existing items with complete tax data
      final existingItems = await txn.query(
        'purchase_item',
        where: 'temp_tag = ? AND purchase_id IS NULL',
        whereArgs: [tempTag],
      );

      // Update items with purchase_id while preserving all fields
      for (final item in existingItems) {
        await txn.update(
          'purchase_item',
          {
            'purchase_id': purchaseId,
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

      return purchaseId;
    });
  }

  // Get all purchases
  static Future<List<Map<String, dynamic>>> getAllPurchases() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single purchase by id
  static Future<Map<String, dynamic>?> getPurchaseById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // Update a purchase
  static Future<int> updatePurchase(Map<String, dynamic> purchase) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      purchase,
      where: 'id = ?',
      whereArgs: [purchase['id']],
    );
  }

  // Delete a purchase with stock adjustment
  static Future<int> deletePurchase(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      final items = await txn.query(
        'purchase_item',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      final purchaseDeleteResult = await txn.delete(
        'purchase',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      if (purchaseDeleteResult == 1 && items.isNotEmpty) {
        for (final item in items) {
          await _adjustStockAfterDeletion(
            txn,
            item['item_name'].toString(),
            int.parse(item['quantity'].toString()),
          );
        }
      }

      await txn.delete(
        'purchase_item',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      return purchaseDeleteResult;
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
      final newStock = currentStock - quantity;

      await txn.update(
        'products',
        {'stockQuantity': newStock},
        where: 'id = ?',
        whereArgs: [product['id']],
      );
    }
  }
}
