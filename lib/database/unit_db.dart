import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class UnitDB {
  static const String tableName = 'units';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');
  }

  static Future<void> insertDefaultUnits(Database db) async {
    List<String> defaultUnits = [
      'Kilogram (KG)',
      'Gram (GM)',
      'Litre (L)',
      'Millilitre (ML)',
      'Piece (PC)',
      'Box (BOX)',
      'Pack (PK)',
      'Dozen (DZ)',
      'Meter (M)',
      'Centimeter (CM)',
      'Inch (IN)',
      'Feet (FT)',
      'Tablet (TAB)',
      'Bottle (BTL)',
      'Set (SET)',
      'Pair (PR)',
      'Roll (RL)',
      'Bag (BAG)',
      'Can (CAN)',
      'Jar (JAR)',
      'Tube (TUBE)',
      'Barrel (BRL)',
      'Ton (TON)',
      'Unit (UNIT)',
    ];

    for (String unit in defaultUnits) {
      await insertUnitRaw(db, unit);
    }
  }

  /// Used internally only during onCreate
  static Future<void> insertUnitRaw(Database db, String name) async {
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Runtime: add new unit
  static Future<void> insertUnit(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(tableName, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Runtime: delete existing unit
  static Future<void> deleteUnit(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName, where: 'name = ?', whereArgs: [name]);
  }

  /// Runtime: fetch all units
  static Future<List<String>> getAllUnits() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(tableName);
    return result.map((e) => e['name'] as String).toList();
  }
}
