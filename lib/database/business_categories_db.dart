import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class BusinessCategoryDB {
  static const String tableName = 'business_categories';

  // Create table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  // Insert default business categories
  static Future<void> insertDefaultCategories(Database db) async {
    List<String> defaultCategories = [
      "Kirana / General Merchant",
      "FMCG Products",
      "Dairy Farm Products / Poultry",
      "Furniture",
      "Garment / Fashion & Hosiery",
      "Jewellery & Gems",
      "Pharmacy / Medical",
      "Hardware Store",
      "Industrial Machinery & Equipment",
      "Mobile & Accessories",
      "Footwear",
      "Paper & Paper Products",
      "Sweet Shop / Bakery",
      "Gifts & Toys",
      "Oil & Gas",
      "Liquor Store",
      "Book / Stationary Store",
      "Construction Materials & Equipment",
      "Chemicals & Fertilizers",
      "Computer Equipments & Softwares",
      "Electrical & Electronics Equipments",
      "Fashion Accessory / Cosmetics",
      "Fruit and Vegetable",
    ];

    for (String category in defaultCategories) {
      await insertCategoryRaw(db, category);
    }
  }

  // Used only during onCreate
  static Future<void> insertCategoryRaw(Database db, String name) async {
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Add new category
  static Future<void> insertCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Delete category
  static Future<void> deleteCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }

  // Runtime: Get all categories
  static Future<List<String>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(tableName);
    return result.map((e) => e['name'] as String).toList();
  }
}
