import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // deepseek api
  static const String _deepSeekKey = 'sk-a00b6f5bd699411f89701a26dced57d4';
  static const String _deepSeekUrl =
      'https://api.deepseek.com/v1/chat/completions';

  // ocr api
  static const String _ocrApiKey = 'K84726173688957';
  static const String _ocrUrl = 'https://api.ocr.space/parse/image';

  // 将图片发送到OCR服务器，base64
  static Future<String> recognizeTextFromImage(Uint8List imageBytes) async {
    try {
      //转base64
      String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      // 构造表单数据
      final response = await http.post(
        Uri.parse(_ocrUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apikey": _ocrApiKey,
          "base64image": base64Image,
          "language": "chs", 
          "isOverlayRequired": "false",
          "scale": "true", // 自动缩放
          "detectOrientation": "true", // 自动纠正方向
          "OCREngine": "2",
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
            "OCR API HTTP Error: ${response.statusCode} ${response.body}");
        return 'Error: ${response.statusCode}';
      }

      // 解析结果
      final Map<String, dynamic> j = jsonDecode(response.body);

      if (j['IsErroredOnProcessing'] == true) {
        String errorMsg = j['ErrorMessage']?.toString() ?? 'Unknown Error';
        debugPrint("OCR Processing Error: $errorMsg");
        if (errorMsg.contains('size limit')) {
          return 'OCR Error: 图片过大，请继续压缩';
        }
        return 'OCR Error: $errorMsg';
      }

      final parsedResults = j['ParsedResults'] as List<dynamic>?;
      if (parsedResults == null || parsedResults.isEmpty) {
        return '';
      }

      String parsedText = parsedResults[0]['ParsedText'] ?? '';
      //清理换行
      return parsedText.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    } catch (e) {
      debugPrint("OCR Request Exception: $e");
      return 'OCR Exception: $e';
    }
  }

  // 发送给 deepseek 整理成 JSON 数据
  static Future<Map<String, dynamic>> analyzeMedicineInfo(
      String ocrText) async {
    try {
      // 优化提示词，强制要求纯 JSON
      final userPrompt = """
请分析以下药品说明书文本，提取关键信息并以纯JSON格式返回。

文本内容：
$ocrText

要求：
1. 必须严格以纯JSON格式返回，不要包含 Markdown 标记（如 ```json ... ```）。
2. 必须包含以下字段：
   - name: 药品名称（字符串）
   - dose: 单次服用剂量（字符串，如"2粒"、"10ml"）
   - frequency: 服用频率（字符串，如"每日3次"、"每8小时1次"）
   - schedule: 根据频率推算的今日服药时间表（字符串数组，格式为"HH:mm"，如["08:00", "12:00", "18:00"]）
   - notes: 注意事项（字符串，简短总结）
3. 如果某些字段无法从文本中找到，请根据常识合理推断或留空。
""";

      final body = jsonEncode({
        "model": "deepseek-chat",
        "messages": [
          {
            "role": "system",
            "content": "你是一位专业的药师助手，擅长从非结构化文本中提取药品使用信息。你只输出标准的JSON格式数据。"
          },
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.1,
        "max_tokens": 1000,
        "response_format": {"type": "json_object"}
      });

      // 发送请求
      final response = await http.post(
        Uri.parse(_deepSeekUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepSeekKey',
        },
        body: utf8.encode(body),
      );

      if (response.statusCode == 200) {
        // 强制 UTF-8 解码，防止中文乱码
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        String content = jsonResponse['choices'][0]['message']['content'];

        // 清理 Markdown 标记
        content =
            content.replaceAll("```json", "").replaceAll("```", "").trim();

        try {
          return jsonDecode(content);
        } catch (e) {
          debugPrint("DeepSeek JSON Parse Error: $content");
          return {};
        }
      } else {
        debugPrint("DeepSeek API请求失败: ${response.statusCode} ${response.body}");
        return {};
      }
    } catch (e) {
      debugPrint("AI分析过程出错: $e");
      return {};
    }
  }

  // 通用AI对话接口，用于主页建议等
  static Future<String> askAI(String systemPrompt, String userPrompt) async {
    try {
      final body = jsonEncode({
        "model": "deepseek-chat",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.7,
        "max_tokens": 500,
      });

      final response = await http.post(
        Uri.parse(_deepSeekUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepSeekKey',
        },
        body: utf8.encode(body),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        return jsonResponse['choices'][0]['message']['content'] ?? "AI无响应";
      } else {
        return "网络请求失败: ${response.statusCode}";
      }
    } catch (e) {
      return "AI服务暂时不可用: $e";
    }
  }
}
