// 菜谱模型 - 存储食物分析结果
class FoodAnalysis {
  String id;            // 分析记录ID
  String foodName;      // 食物名称
  String imagePath;     // 图片本地路径
  List<String> ingredients; // 识别的食材列表
  String calories;      // 热量估算，如"约300大卡"
  String protein;       // 蛋白质含量，如"15g"
  String carbs;         // 碳水化合物含量，如"45g"
  String fat;           // 脂肪含量，如"12g"
  String suggestion;    // 健康建议
  DateTime analyzedAt;  // 分析时间

  FoodAnalysis({
    required this.id,
    required this.foodName,
    required this.imagePath,
    required this.ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.suggestion,
    required this.analyzedAt,
  });

  // 从JSON创建
  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    // 处理 AI 返回的简化格式（可能没有 id、imagePath 等字段）
    return FoodAnalysis(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: json['foodName'] ?? json['name'] ?? '未知食物',
      imagePath: json['imagePath'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      calories: json['calories'] ?? '未计算',
      protein: json['protein'] ?? '未知',
      carbs: json['carbs'] ?? '未知',
      fat: json['fat'] ?? '未知',
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
      'suggestion': suggestion,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  // 获取简短描述
  String getShortDescription() {
    return '$calories • 蛋白$protein • 碳水$carbs • 脂肪$fat';
  }
}
