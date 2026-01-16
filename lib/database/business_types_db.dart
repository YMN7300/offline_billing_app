import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class BusinessTypeDB {
  static const String tableName = 'business_types';

  // Create table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  // Insert default business types
  static Future<void> insertDefaultTypes(Database db) async {
    List<String> defaultTypes = [
      "Retail",
      "Wholesale",
      "Manufacturing",
      "Distributor",
      "Other",
    ];

    for (String type in defaultTypes) {
      await insertTypeRaw(db, type);
    }
  }

  // Used only during onCreate
  static Future<void> insertTypeRaw(Database db, String name) async {
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Add new type
  static Future<void> insertType(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Delete type
  static Future<void> deleteType(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }

  // Runtime: Get all types
  static Future<List<String>> getAllTypes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(tableName);
    return result.map((e) => e['name'] as String).toList();
  }
}
