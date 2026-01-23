import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // 单例模式：确保全局只有一个数据库实例
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  // 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库（创建数据库文件+建表）
  Future<Database> _initDatabase() async {
    // 1. 获取数据库存储路径（移动端：应用沙盒路径；Web需特殊处理）
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'health_db.db'); // 数据库文件名

    // 2. 打开/创建数据库（version=1：首次创建；后续升级需改版本号）
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // 数据库首次创建时执行（建表）
    );
  }

  // 数据库首次创建时，执行建表语句
  Future<void> _onCreate(Database db, int version) async {
    // 建表1：饮食记录表（对应你的模块二需求）
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

    // （可选）建表2：用户表（如果后续需要用户信息）
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // （基础操作示例）插入数据（以饮食记录为例）
  Future<int> insertDietRecord(Map<String, dynamic> record) async {
    Database db = await instance.database;
    return await db.insert('diet_records', record);
  }

  // （基础操作示例）查询所有饮食记录
  Future<List<Map<String, dynamic>>> getDietRecords() async {
    Database db = await instance.database;
    return await db.query('diet_records');
  }
}