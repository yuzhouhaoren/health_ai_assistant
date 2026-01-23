import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diet_record.dart'; // 确保此导入路径正确


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDir.path, 'health_manager.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diet_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredients TEXT NOT NULL,
        calories TEXT NOT NULL,
        nutrition TEXT NOT NULL,
        suitable_for TEXT NOT NULL,
        advice TEXT NOT NULL,
        create_time DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // 插入饮食记录
  Future<int> insertDietRecord(DietRecord record) async {
    final db = await instance.database;
    return await db.insert(
      'diet_records',
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 查询近days天的饮食记录
  Future<List<DietRecord>> getRecentDietRecords(int days) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> recordsMap = await db.query(
      'diet_records',
      where: "create_time >= datetime('now', '-? days')",
      whereArgs: [days],
      orderBy: 'create_time DESC',
    );

    return List.generate(recordsMap.length, (i) {
      return DietRecord.fromJson(recordsMap[i]);
    });
  }

  // 查询所有饮食记录
  Future<List<DietRecord>> getAllDietRecords() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> recordsMap = await db.query(
      'diet_records',
      orderBy: 'create_time DESC',
    );

    return List.generate(recordsMap.length, (i) {
      return DietRecord.fromJson(recordsMap[i]);
    });
  }

  // 删除指定ID的饮食记录
  Future<int> deleteDietRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'diet_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}