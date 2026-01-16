import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class CustomerDB {
  static const String tableName = 'customer';

  // Create the customer table
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

  // Insert a new customer
  static Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(tableName, customer);
  }

  // Get all customers
  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  // Get a single customer by id
  static Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Update a customer
  static Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  // Delete a customer by id
  static Future<int> deleteCustomer(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllCustomersForReturn() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('customers');
  }
}
