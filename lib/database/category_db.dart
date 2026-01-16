import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class CategoryDB {
  static const String tableName = 'categories';

  /// Table creation
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  /// Default categories for first launch
  static Future<void> insertDefaultCategories(Database db) async {
    List<String> defaultCategories = [
      'Electronics',
      'Grocery',
      'Clothing',
      'Stationery',
    ];

    for (String category in defaultCategories) {
      await insertCategoryRaw(db, category);
    }
  }

  /// Only used during onCreate
  static Future<int> insertCategoryRaw(Database db, String name) async {
    return await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Runtime insert (user adds new category)
  static Future<void> insertCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<List<String>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(tableName);
    return result.map((row) => row['name'] as String).toList();
  }

  static Future<int> deleteCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }
}
