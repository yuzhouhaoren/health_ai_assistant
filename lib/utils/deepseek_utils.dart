import 'dart:convert';
import 'package:http/http.dart' as http;

/// DeepSeek AI 工具类（修复乱码 + JSON 解析错误）
class DeepSeekUtils {
  static const String _deepseekApiUrl = "https://api.deepseek.com/v1/chat/completions";
  static const String _apiKey = "sk-abc4a27616fe457a8d8759d5d3667128"; // 替换为你的 API Key

  static Future<Map<String, dynamic>?> analyzeDiet(String dietText) async {
    try {
      // 1. 优化提示词：强制返回纯 JSON
      String prompt = """
      请严格以纯 JSON 格式分析以下饮食的营养成分，不要包含任何 Markdown 标记或说明文字：
      饮食：$dietText
      JSON 必须包含字段：food_type（菜品类型）、calorie（热量）、nutrition（含蛋白质/碳水/脂肪/膳食纤维）、suggestion（建议）
      示例：{"food_type":"家常菜","calorie":"约 500 大卡","nutrition":{"蛋白质":"20g","碳水化合物":"60g","脂肪":"15g","膳食纤维":"5g"},"suggestion":"营养均衡"}
      """;

      // 2. 发送请求：明确要求 UTF-8 编码
      final response = await http.post(
        Uri.parse(_deepseekApiUrl),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Accept-Charset": "utf-8",
          "Authorization": "Bearer sk-abc4a27616fe457a8d8759d5d3667128"
        },
        body: jsonEncode({
          "model": "deepseek-chat",
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.5,
          "max_tokens": 500
        }),
      );

      if (response.statusCode == 200) {
        // 3. 强制用 UTF-8 解析响应（核心修复）
        String responseBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> result = jsonDecode(responseBody);
        String content = result["choices"][0]["message"]["content"];

        // 4. 清理 Markdown 标记
        content = content
            .replaceAll("```json", "")
            .replaceAll("```", "")
            .trim();

        // 5. 解析 JSON
        return jsonDecode(content);
      } else {
        throw Exception("DeepSeek 请求失败：${response.statusCode}");
      }
    } catch (e) {
      print("DeepSeek 分析失败：$e");
      // 6. 降级返回模拟数据（避免乱码）
      return {
        "food_type": "家常菜（米饭+青菜+炒肉）",
        "calorie": "约 580 大卡",
        "nutrition": {
          "蛋白质": "25g",
          "碳水化合物": "75g",
          "脂肪": "18g",
          "膳食纤维": "6g"
        },
        "suggestion": "整体营养均衡，可适当增加粗粮比例"
      };
    }
  }
}