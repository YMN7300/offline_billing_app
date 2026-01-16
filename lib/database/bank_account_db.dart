import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class BankAccountDB {
  static const String tableName = 'bank_accounts';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bankName TEXT NOT NULL,
        holderName TEXT NOT NULL,
        accountNumber TEXT NOT NULL UNIQUE,
        ifscCode TEXT NOT NULL,
        branchName TEXT,
        upiId TEXT,
        openingBalance REAL DEFAULT 0.0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<int> insertOrUpdateBankAccount(
    BankAccountModel bankAccount,
  ) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Check if bank account exists with same account number
      final existingAccounts = await db.query(
        tableName,
        where: 'accountNumber = ?',
        whereArgs: [bankAccount.accountNumber],
        limit: 1,
      );

      if (existingAccounts.isEmpty) {
        // Insert new bank account
        return await db.insert(tableName, bankAccount.toMap());
      } else {
        // Update existing bank account
        final existingId = existingAccounts.first['id'] as int;
        return await db.update(
          tableName,
          {
            ...bankAccount.toMap(),
            'id': existingId, // Preserve the existing ID
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );
      }
    } catch (e) {
      print('Error in insertOrUpdateBankAccount: $e');
      rethrow;
    }
  }

  static Future<List<BankAccountModel>> getAllBankAccounts({
    bool activeOnly = true,
  }) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final whereClause = activeOnly ? 'WHERE isActive = 1' : '';
      final maps = await db.rawQuery('''
        SELECT * FROM $tableName 
        $whereClause 
        ORDER BY bankName, holderName
      ''');

      return maps.map((map) => BankAccountModel.fromMap(map)).toList();
    } catch (e) {
      print('Error in getAllBankAccounts: $e');
      rethrow;
    }
  }

  static Future<BankAccountModel?> getBankAccountById(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BankAccountModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in getBankAccountById: $e');
      rethrow;
    }
  }

  static Future<BankAccountModel?> getBankAccountByAccountNumber(
    String accountNumber,
  ) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final maps = await db.query(
        tableName,
        where: 'accountNumber = ?',
        whereArgs: [accountNumber],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BankAccountModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in getBankAccountByAccountNumber: $e');
      rethrow;
    }
  }

  static Future<int> deleteBankAccount(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error in deleteBankAccount: $e');
      rethrow;
    }
  }

  static Future<int> softDeleteBankAccount(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.update(
        tableName,
        {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error in softDeleteBankAccount: $e');
      rethrow;
    }
  }

  static Future<int> getBankAccountsCount() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE isActive = 1'),
      );
      return count ?? 0;
    } catch (e) {
      print('Error in getBankAccountsCount: $e');
      return 0;
    }
  }

  static Future<void> updateBankAccountBalance(
    int id,
    double newBalance,
  ) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.update(
        tableName,
        {
          'openingBalance': newBalance,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error in updateBankAccountBalance: $e');
      rethrow;
    }
  }
}

class BankAccountModel {
  final int? id;
  final String bankName;
  final String holderName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String? upiId;
  final double openingBalance;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  BankAccountModel({
    this.id,
    required this.bankName,
    required this.holderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branchName,
    this.upiId,
    this.openingBalance = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'holderName': holderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'upiId': upiId,
      'openingBalance': openingBalance,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static BankAccountModel fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id'] as int?,
      bankName: map['bankName'] as String,
      holderName: map['holderName'] as String,
      accountNumber: map['accountNumber'] as String,
      ifscCode: map['ifscCode'] as String,
      branchName: map['branchName'] as String,
      upiId: map['upiId'] as String?,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  BankAccountModel copyWith({
    int? id,
    String? bankName,
    String? holderName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? upiId,
    double? openingBalance,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      holderName: holderName ?? this.holderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '$bankName - $accountNumber ($holderName)';
  }
}
