import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; //设置content-type
import 'package:mime/mime.dart'; //判断文件类型

class ApiService {
  // deepseek api
  static const String _deepSeekKey = 'sk-a00b6f5bd699411f89701a26dced57d4';
  static const String _deepSeekUrl =
      'https://api.deepseek.com/v1/chat/completions';

  // ocr api
  static const String _ocrApiKey = 'K84726173688957';
  static const String _ocrUrl = 'https://api.ocr.space/parse/image';

  //将图片发送到OCR服务器，拿回识别到的文字
  static Future<String> recognizeTextFromImage(String imagePath) async {
    try {
      Future<String> _callOcr(String lang) async {
        var request = http.MultipartRequest('POST', Uri.parse(_ocrUrl));
        request.fields['apikey'] = _ocrApiKey;
        request.fields['language'] = lang;

        //构建http请求
        final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
        final parts = mimeType.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imagePath,
          contentType: MediaType(parts[0], parts[1]),
        ));

        //处理http响应
        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode != 200) return ' ';
        final Map<String, dynamic> j = jsonDecode(resp.body);
        if (j['IsErroredOnProcessing'] == true) return '';
        final parsed = (j['ParsedResults'] as List<dynamic>?);
        if (parsed == null || parsed.isEmpty) return '';
        return (parsed[0]['ParsedText'] as String?) ?? '';
      }

      String textCh = await _callOcr('chs');
      textCh = textCh.replaceAll(RegExp(r'\s+'), ' ').trim();
      //检测说明中是否含英文
      final hasChinese = RegExp(r'[\ue400-\u9fff]').hasMatch(textCh);
      final hasEnglish = RegExp(r'[A-Za-z]').hasMatch(textCh);
      if (!hasEnglish) {
        String textEn = await _callOcr('eng');
        textEn = textEn.replaceAll(RegExp(r'\s+'), ' ').trim();
        String chosen = textCh;
        if (textEn.isNotEmpty && textEn.length > textCh.length) {
          chosen = textEn;
        }

        if (chosen.isEmpty) return '识别结果为空';
        return chosen;
      }
      //返回识别文字
      if (textCh.isEmpty) return '识别结果为空';
      return textCh;
    } catch (e) {
      return 'OCR识别错误:$e';
    }
  }

  //发送给deepseek整理成JSON数据
  static Future<Map<String, dynamic>> analyzeMedicineInfo(
      String ocrText) async {
    try {
      //构建提示词
      final userPrompt = """
请分析以下药品说明书文本，提取关键信息并以纯JSON格式返回。

文本内容：
$ocrText

要求：
1. 只返回JSON对象，不要包含Markdown标记（如 ```json ... ```）。
2. 必须包含以下字段：
   - name: 药品名称（字符串）
   - dose: 单次服用剂量（字符串，如"2粒"、"10ml"）
   - frequency: 服用频率（字符串，如"每日3次"、"每8小时1次"）
   - schedule: 根据频率推算的今日服药时间表（字符串数组，格式为"HH:mm"，如["08:00", "12:00", "18:00"]）
   - notes: 注意事项（字符串，简短总结）
3. 如果某些字段无法从文本中找到，请根据常识合理推断或留空。
""";

      //构建请求体
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
        "response_format": {"type": "json_object"}
      });

      //发送POST请求
      final response = await http.post(
        Uri.parse(_deepSeekUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_deepSeekKey',
        },
        body: utf8.encode(body),
      );

      //解析结果
      if (response.statusCode == 200) {
        //解析响应体
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        //content字符串解析为JSON对象
         try {
          return jsonDecode(content);
        } catch (e) {
          print("DeepSeek返回的不是有效JSON: $content");
          return {};
        }
      } else {
        print("DeepSeek API请求失败: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("AI分析过程出错: $e");
      return {};
    }
  }
}
