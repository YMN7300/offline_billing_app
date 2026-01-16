import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class StateDB {
  static const String tableName = 'states';

  // Create table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  // Insert default Indian states
  static Future<void> insertDefaultStates(Database db) async {
    List<String> defaultStates = [
      "Andaman and Nicobar Islands",
      "Andhra Pradesh",
      "Arunachal Pradesh",
      "Assam",
      "Bihar",
      "Chandigarh",
      "Chhattisgarh",
      "Dadra and Nagar Haveli and Daman and Diu",
      "Delhi",
      "Goa",
      "Gujarat",
      "Haryana",
      "Himachal Pradesh",
      "Jammu and Kashmir",
      "Jharkhand",
      "Karnataka",
      "Kerala",
      "Ladakh",
      "Lakshadweep",
      "Madhya Pradesh",
      "Maharashtra",
      "Manipur",
      "Meghalaya",
      "Mizoram",
      "Nagaland",
      "Odisha",
      "Puducherry",
      "Punjab",
      "Rajasthan",
      "Sikkim",
      "Tamil Nadu",
      "Telangana",
      "Tripura",
      "Uttar Pradesh",
      "Uttarakhand",
      "West Bengal",
    ];

    for (String state in defaultStates) {
      await insertStateRaw(db, state);
    }
  }

  // Used only during onCreate
  static Future<void> insertStateRaw(Database db, String name) async {
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Add new state
  static Future<void> insertState(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Runtime: Delete state
  static Future<void> deleteState(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }

  // Runtime: Get all states
  static Future<List<String>> getAllStates() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(tableName);
    return result.map((e) => e['name'] as String).toList();
  }
}
