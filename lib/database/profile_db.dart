import 'package:sqflite/sqflite.dart';

import 'db/database_helper.dart';

class ProfileDB {
  static const String tableName = 'profile';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        businessName TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        city TEXT,
        pincode TEXT,
        state TEXT,
        gst TEXT,
        businessType TEXT,
        businessCategory TEXT,
        imagePath TEXT
      )
    ''');
  }

  static Future<int> insertOrUpdateProfile(ProfileModel profile) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Check if profile exists
      final existingProfiles = await db.query(
        tableName,
        limit: 1,
        orderBy: 'id DESC', // Get the most recent profile
      );

      if (existingProfiles.isEmpty) {
        // Insert new profile
        return await db.insert(tableName, profile.toMap());
      } else {
        // Update existing profile
        final existingId = existingProfiles.first['id'] as int;
        return await db.update(
          tableName,
          {
            ...profile.toMap(),
            'id': existingId, // Preserve the existing ID
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );
      }
    } catch (e) {
      print('Error in insertOrUpdateProfile: $e');
      rethrow;
    }
  }

  static Future<ProfileModel?> getProfile() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final maps = await db.query(
        tableName,
        limit: 1,
        orderBy: 'id DESC', // Get the most recent profile
      );

      if (maps.isNotEmpty) {
        return ProfileModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
  }

  static Future<void> deleteProfile() async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.delete(tableName);
    } catch (e) {
      print('Error in deleteProfile: $e');
      rethrow;
    }
  }

  static Future<int> getProfileCount() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      );
      return count ?? 0;
    } catch (e) {
      print('Error in getProfileCount: $e');
      return 0;
    }
  }
}

class ProfileModel {
  final int? id;
  final String businessName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String pincode;
  final String state;
  final String gst;
  final String businessType;
  final String businessCategory;
  final String? imagePath;

  ProfileModel({
    this.id,
    required this.businessName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.pincode,
    required this.state,
    required this.gst,
    required this.businessType,
    required this.businessCategory,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'pincode': pincode,
      'state': state,
      'gst': gst,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'imagePath': imagePath,
    };
  }

  static ProfileModel fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as int?,
      businessName: map['businessName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      pincode: map['pincode'] as String,
      state: map['state'] as String,
      gst: map['gst'] as String,
      businessType: map['businessType'] as String,
      businessCategory: map['businessCategory'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  ProfileModel copyWith({
    int? id,
    String? businessName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? pincode,
    String? state,
    String? gst,
    String? businessType,
    String? businessCategory,
    String? imagePath,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      state: state ?? this.state,
      gst: gst ?? this.gst,
      businessType: businessType ?? this.businessType,
      businessCategory: businessCategory ?? this.businessCategory,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
