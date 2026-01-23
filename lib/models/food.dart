// 菜谱模型 - 存储食物分析结果
class FoodAnalysis {
  String id;            // 分析记录ID
  String foodName;      // 食物名称
  String imagePath;     // 图片本地路径
  List<String> ingredients; // 识别的食材列表
  String calories;      // 热量估算，如"约300大卡"
  List<String> nutrition;   // 主要营养成分
  List<String> suitableFor; // 适合人群
  String advice;        // 健康建议
  DateTime analyzedAt;  // 分析时间

  FoodAnalysis({
    required this.id,
    required this.foodName,
    required this.imagePath,
    required this.ingredients,
    required this.calories,
    required this.nutrition,
    required this.suitableFor,
    required this.advice,
    required this.analyzedAt,
  });

  // 从JSON创建
  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: json['foodName'] ?? '未知食物',
      imagePath: json['imagePath'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      calories: json['calories'] ?? '未计算',
      nutrition: (json['nutrition'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      suitableFor: (json['suitableFor'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      advice: json['advice'] ?? '无特别建议',
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
      'nutrition': nutrition,
      'suitableFor': suitableFor,
      'advice': advice,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  // 获取简短描述
  String getShortDescription() {
    return '$calories • ${nutrition.take(2).join('、')}';
  }
}