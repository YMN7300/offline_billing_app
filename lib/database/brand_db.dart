import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class BrandDB {
  static const String tableName = 'brands';

  /// Table creation
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  /// Default brands for first launch
  static Future<void> insertDefaultBrands(Database db) async {
    List<String> defaultBrands = ['Sony', 'Samsung', 'Apple', 'LG'];

    for (String brand in defaultBrands) {
      await insertBrandRaw(db, brand);
    }
  }

  /// Only used during onCreate
  static Future<int> insertBrandRaw(Database db, String name) async {
    return await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Runtime insert (user adds new brand)
  static Future<void> insertBrand(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<List<String>> getAllBrands() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(tableName);
    return result.map((row) => row['name'] as String).toList();
  }

  static Future<int> deleteBrand(String name) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }
}
