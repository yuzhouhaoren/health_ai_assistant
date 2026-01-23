import 'dart:convert';
import 'package:intl/intl.dart';

class DietRecord {
  final int? id;
  final String ingredients; // 识别的食材
  final String calories; // 热量
  final List<String> nutrition; // 营养成分
  final List<String> suitableFor; // 适合人群
  final String advice; // 健康建议
  final String createTime; // 创建时间

  // 构造函数
  DietRecord({
    this.id,
    required this.ingredients,
    required this.calories,
    required this.nutrition,
    required this.suitableFor,
    required this.advice,
    String? createTime,
  }) : createTime = createTime ?? DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

  // 将对象转为Map（用于插入数据库）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredients': ingredients,
      'calories': calories,
      'nutrition': json.encode(nutrition), // 列表转JSON字符串
      'suitable_for': json.encode(suitableFor), // 列表转JSON字符串
      'advice': advice,
      'create_time': createTime,
    };
  }

  // 从数据库的Map转为对象
  factory DietRecord.fromJson(Map<String, dynamic> map) { // 参数名改为map
    return DietRecord(
      id: map['id'],
      ingredients: map['ingredients'],
      calories: map['calories'],
      // 调用dart:convert的json.decode解析字符串（此时json是工具类，不是参数）
      nutrition: List<String>.from(json.decode(map['nutrition'])),
      suitableFor: List<String>.from(json.decode(map['suitable_for'])),
      advice: map['advice'],
      createTime: map['create_time'],
    );
  }
}