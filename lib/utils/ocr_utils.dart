import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 新增导入
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const String OCR_API_KEY = "你的OCR.space API Key";
const String OCR_API_URL = "https://api.ocr.space/parse/image";

class OcrUtils {
  static Future<String> imageToBase64(File imageFile) async {
    List<int> imageBytesList = await imageFile.readAsBytes();
    Uint8List imageBytes = Uint8List.fromList(imageBytesList); // 类型转换

    img.Image? compressedImage = img.decodeImage(imageBytes);
    if (compressedImage != null) {
      compressedImage = img.resize(compressedImage, width: 800);
      imageBytes = Uint8List.fromList(img.encodeJpg(compressedImage, quality: 80));
    }
    return base64Encode(imageBytes);
  }

  static Future<String?> extractIngredients(File imageFile) async {
    try {
      String base64Image = await imageToBase64(imageFile);

      final response = await http.post(
        Uri.parse(OCR_API_URL),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apikey": OCR_API_KEY,
          "base64Image": "data:image/jpg;base64,$base64Image",
          "language": "chs",
          "isOverlayRequired": "false",
          "filetype": "jpg"
        },
      ).timeout(const Duration(seconds: 15)); // 修正timeout位置

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        if (result["IsErroredOnProcessing"] == false) {
          String parsedText = result["ParsedResults"][0]["ParsedText"];
          return parsedText.trim();
        } else {
          throw Exception("OCR识别失败：${result["ErrorMessage"]}");
        }
      } else {
        throw Exception("OCR接口请求失败：${response.statusCode}");
      }
    } catch (e) {
      print("OCR工具类异常：$e");
      return null;
    }
  }
}