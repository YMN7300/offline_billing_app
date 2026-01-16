import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class VendorDB {
  static const String tableName = 'vendor';

  // Create the vendor table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        gstin TEXT NOT NULL,
        address TEXT,
        pincode TEXT,
        city TEXT,
        state TEXT
      )
    ''');
  }

  // Insert a new vendor
  static Future<int> insertVendor(Map<String, dynamic> vendor) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, vendor);
  }

  // Get all vendors
  static Future<List<Map<String, dynamic>>> getAllVendors() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single vendor by id
  static Future<Map<String, dynamic>?> getVendorById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Update a vendor
  static Future<int> updateVendor(Map<String, dynamic> vendor) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      vendor,
      where: 'id = ?',
      whereArgs: [vendor['id']],
    );
  }

  // Delete a vendor by id
  static Future<int> deleteVendor(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
