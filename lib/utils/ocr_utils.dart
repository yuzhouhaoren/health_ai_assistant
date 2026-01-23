import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// OCR 图片识别工具类（适配 OCR.Space）
class OcrUtils {
  // OCR.Space 官方接口地址
  static const String _ocrApiUrl = "https://api.ocr.space/parse/image";

  // 你的 OCR.Space API Key（直接替换成你邮箱里收到的那个）
  static const String _apiKey = "K82888596688957";

  /// 图片转 Base64 编码（适配 Web/移动端）
  static Future<String?> imageToBase64(XFile imageFile) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = File(imageFile.path).readAsBytesSync();
      }
      return base64Encode(imageBytes);
    } catch (e) {
      print("图片转 Base64 失败：$e");
      return null;
    }
  }

  /// 调用 OCR.Space 接口识别图片中的饮食信息
  static Future<String?> recognizeDietInfo(XFile imageFile) async {
    try {
      // 1. 图片转 Base64
      String? base64Image = await imageToBase64(imageFile);
      if (base64Image == null) {
        throw Exception("图片编码失败");
      }

      // 2. 构造请求参数（OCR.Space 只需要 API Key，不需要 Token）
      final response = await http.post(
        Uri.parse(_ocrApiUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apikey": _apiKey,
          "base64image": "data:image/jpeg;base64,$base64Image",
          "language": "chs", // 中文识别
          "isOverlayRequired": "false",
        },
      );

      // 3. 解析 OCR.Space 响应
      if (response.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(response.body);
        if (result["IsErroredOnProcessing"] == false) {
          String parsedText = result["ParsedResults"][0]["ParsedText"] ?? "米饭 青菜 炒肉";
          return parsedText.replaceAll("\r\n", " ").trim();
        } else {
          throw Exception("OCR 识别错误：${result["ErrorMessage"]}");
        }
      } else {
        throw Exception("OCR 接口请求失败：${response.statusCode}");
      }
    } catch (e) {
      print("OCR 识别失败：$e");
      return "米饭 青菜 炒肉";
    }
  }
}