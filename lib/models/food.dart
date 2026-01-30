// 菜谱模型 - 存储食物分析结果

// 份量枚举
enum PortionSize {
  small('一小份', 0.5),      // 小份：5折
  medium('一份', 1.0),       // 标准份：1倍
  large('一大份', 1.5);      // 大份：5倍

  final String label;
  final double multiplier;

  const PortionSize(this.label, this.multiplier);
}

// 营养素数据类
class NutritionInfo {
  int calories;     // 热量（大卡）
  double protein;   // 蛋白质（克）
  double carbs;     // 碳水（克）
  double fat;       // 脂肪（克）

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // 根据份量计算实际营养素
  NutritionInfo scaled(PortionSize portion) {
    return NutritionInfo(
      calories: (calories * portion.multiplier).round(),
      protein: protein * portion.multiplier,
      carbs: carbs * portion.multiplier,
      fat: fat * portion.multiplier,
    );
  }

  // 转换为格式化的字符串
  String get formattedCalories => '约 $calories 大卡';
  String get formattedProtein => '${protein.toStringAsFixed(1)}g';
  String get formattedCarbs => '${carbs.toStringAsFixed(1)}g';
  String get formattedFat => '${fat.toStringAsFixed(1)}g';
}

class FoodAnalysis {
  String id;            // 分析记录ID
  String foodName;      // 食物名称
  String imagePath;     // 图片本地路径
  List<String> ingredients; // 识别的食材列表

  // 原始营养素数据（基于标准份）
  int baseCalories;     // 基础热量
  double baseProtein;   // 基础蛋白质
  double baseCarbs;     // 基础碳水
  double baseFat;       // 基础脂肪

  // 显示用的营养素（根据份量计算）
  String calories;      // 显示的热量
  String protein;       // 显示的蛋白质
  String carbs;         // 显示的碳水
  String fat;           // 显示的脂肪

  PortionSize portion;  // 当前选择的份量
  String suggestion;    // 健康建议
  DateTime analyzedAt;  // 分析时间

  // 获取实际营养素（根据份量）
  NutritionInfo get actualNutrition {
    return NutritionInfo(
      calories: baseCalories,
      protein: baseProtein,
      carbs: baseCarbs,
      fat: baseFat,
    ).scaled(portion);
  }

  FoodAnalysis({
    required this.id,
    required this.foodName,
    required this.imagePath,
    required this.ingredients,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portion,
    required this.suggestion,
    required this.analyzedAt,
  });

  // 从JSON创建
  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    // 解析份量
    PortionSize portion = PortionSize.medium;
    if (json['portion'] != null) {
      try {
        portion = PortionSize.values.firstWhere(
          (p) => p.name == json['portion'],
          orElse: () => PortionSize.medium,
        );
      } catch (e) {
        portion = PortionSize.medium;
      }
    }

    // 解析原始营养素
    int baseCals = parseCalories(json['calories'] ?? '0');
    double baseProt = parseNutrient(json['protein'] ?? '0');
    double baseCarb = parseNutrient(json['carbs'] ?? '0');
    double baseF = parseNutrient(json['fat'] ?? '0');

    return FoodAnalysis(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: json['foodName'] ?? json['name'] ?? '未知食物',
      imagePath: json['imagePath'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      baseCalories: baseCals,
      baseProtein: baseProt,
      baseCarbs: baseCarb,
      baseFat: baseF,
      calories: json['calories'] ?? '未计算',
      protein: json['protein'] ?? '未知',
      carbs: json['carbs'] ?? '未知',
      fat: json['fat'] ?? '未知',
      portion: portion,
      suggestion: json['suggestion'] ?? json['advice'] ?? '无特别建议',
      analyzedAt: DateTime.parse(json['analyzedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'imagePath': imagePath,
      'ingredients': ingredients,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portion': portion.name,
      'suggestion': suggestion,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  // 解析热量字符串为数字
  static int parseCalories(String str) {
    try {
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(str);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // 解析营养素字符串为数字
  static double parseNutrient(String str) {
    try {
      RegExp regExp = RegExp(r'([\d.]+)');
      Match? match = regExp.firstMatch(str);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // 获取简短描述
  String getShortDescription() {
    return '$calories • 蛋白$protein • 碳水$carbs • 脂肪$fat';
  }
}
