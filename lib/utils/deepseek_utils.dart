import 'dart:convert';
import 'package:http/http.dart' as http;

// 替换成你自己的DeepSeek API密钥
const String DEEPSEEK_API_KEY = "sk-abc4a27616fe457a8d8759d5d3667128";
const String DEEPSEEK_API_URL = "https://api.deepseek.com/v2/chat/completions";

// 营养分析结果模型（和Prompt的JSON格式对应）
class NutritionResult {
  final String calories; // 热量
  final List<String> nutrition; // 主要营养成分（把string改成String）
  final List<String> suitableFor; // 适合人群（把string改成String）
  final String advice; // 健康建议

  // 构造函数（写法正确，配合正确类型即可）
  NutritionResult({
    required this.calories,
    required this.nutrition,
    required this.suitableFor,
    required this.advice,
  });

  // JSON转模型
  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      calories: json["calories"] ?? "未知",
      nutrition: List<String>.from(json["nutrition"] ?? []),
      suitableFor: List<String>.from(json["suitableFor"] ?? []), // 注意和Prompt里的key对应
      advice: json["advice"] ?? "无特殊建议",
    );
  }
}

class DeepSeekUtils {
  /// 分析食材营养（传入OCR识别的食材文字，返回分析结果）
  static Future<NutritionResult?> analyzeIngredients(String ingredients) async {
    try {
      // 构造Prompt（严格按照项目要求的格式）
      // 构造Prompt时，把"suitable_for"改成"suitableFor"
      String prompt = """
分析以下食材的营养成分，并给出：
- 总热量估算
- 主要营养成分
- 适合人群
- 健康建议（如：减盐、少油）

食材：$ingredients

返回JSON格式（仅返回JSON，不要其他文字）：
{
  "calories": "约300大卡",
  "nutrition": ["蛋白质", "碳水化合物", ...],
  "suitableFor": ["一般人群", "健身者"], // 这里改成和模型一致的suitableFor
  "advice": "建议减少用油量"
}
""";

      final response = await http.post(
        Uri.parse(DEEPSEEK_API_URL),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $DEEPSEEK_API_KEY",
        },
        body: json.encode({
          "model": "deepseek-chat",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "stream": false
        }),
      ).timeout(const Duration(seconds: 20)); // 把超时放在这里！

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        String jsonStr = result["choices"][0]["message"]["content"].trim();
        // 解析DeepSeek返回的JSON
        Map<String, dynamic> nutritionJson = json.decode(jsonStr);
        return NutritionResult.fromJson(nutritionJson);
      } else {
        throw Exception("DeepSeek接口请求失败：${response.statusCode}");
      }
    } catch (e) {
      print("DeepSeek工具类异常：$e");
      return null;
    }
  }
}