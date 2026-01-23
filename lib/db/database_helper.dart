import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    // 1. 获取数据库存储路径
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'health_db.db'); // 数据库文件名

    // 2. 打开/创建数据库
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diet_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredients TEXT NOT NULL,  -- 识别的食材
        calories TEXT NOT NULL,     -- 热量
        nutrition TEXT NOT NULL,    -- 营养成分（JSON字符串）
        suitable_for TEXT NOT NULL, -- 适合人群（JSON字符串）
        advice TEXT NOT NULL,       -- 健康建议
        create_time DATETIME DEFAULT CURRENT_TIMESTAMP -- 记录时间
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> insertDietRecord(Map<String, dynamic> record) async {
    Database db = await instance.database;
    return await db.insert('diet_records', record);
  }

  Future<List<Map<String, dynamic>>> getDietRecords() async {
    Database db = await instance.database;
    return await db.query('diet_records');
  }
}