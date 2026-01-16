import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../bank_account_db.dart';
import '../brand_db.dart';
import '../business_categories_db.dart';
import '../business_types_db.dart';
import '../category_db.dart';
import '../customer_db.dart';
import '../product_db.dart';
import '../profile_db.dart';
import '../purchase_db.dart';
import '../purchase_item_db.dart';
import '../purchase_return_db.dart';
import '../purchase_return_item_db.dart';
import '../sales_db.dart';
import '../sales_item_db.dart';
import '../sales_return_db.dart';
import '../sales_return_item_db.dart';
import '../state_db.dart';
import '../unit_db.dart';
import '../vendor_db.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Incremented version number
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('PRAGMA foreign_keys = ON');
        }
        if (oldVersion < 4) {
          // Add sales return tables if upgrading from version < 4
          await SalesReturnDB.createTable(db);
          await SalesReturnItemDB.createTable(db);
        }
        if (oldVersion < 5) {
          await BankAccountDB.createTable(db);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print('🛠️ Creating tables...');
    await ProductDB.createTable(db);
    await UnitDB.createTable(db);
    await CategoryDB.createTable(db);
    await BrandDB.createTable(db);
    await VendorDB.createTable(db);
    await CustomerDB.createTable(db);
    await StateDB.createTable(db);
    await PurchaseDB.createTable(db);
    await PurchaseItemDB.createTable(db);
    await PurchaseReturnDB.createTable(db);
    await PurchaseReturnItemDB.createTable(db);
    await SalesDB.createTable(db);
    await SalesItemDB.createTable(db);
    await SalesReturnDB.createTable(db);
    await SalesReturnItemDB.createTable(db);
    await BusinessCategoryDB.createTable(db);
    await BusinessTypeDB.createTable(db);
    await ProfileDB.createTable(db);
    await BankAccountDB.createTable(db);
    print('✅ All tables created');

    // Default units
    await UnitDB.insertDefaultUnits(db);

    // Default categories
    await CategoryDB.insertDefaultCategories(db);

    // Default brands
    await BrandDB.insertDefaultBrands(db);

    // Default states
    await StateDB.insertDefaultStates(db);

    // Default business categories
    await BusinessTypeDB.insertDefaultTypes(db);
  }

  Future<void> cleanupOrphanedItems() async {
    final db = await database;
    try {
      // Delete purchase items without a purchase
      await db.delete(PurchaseItemDB.tableName, where: 'purchase_id IS NULL');

      // Similarly for sales items
      await db.delete(SalesItemDB.tableName, where: 'sales_id IS NULL');

      // And for return items
      await db.delete(SalesReturnItemDB.tableName, where: 'return_id IS NULL');
    } catch (e) {
      print('Error cleaning up orphaned items: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
