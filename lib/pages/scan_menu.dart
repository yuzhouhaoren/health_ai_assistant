import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/database.dart';
import '../models/food.dart';

// ==================== 调试标志 ====================
const bool _kEnableDebug = true; // 设为true时启用调试输出

// ==================== 调试日志函数 ====================
void _debugPrint(String tag, String message) {
  if (_kEnableDebug) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    print('[$timestamp] [SCAN_MENU:$tag] $message');
  }
}

class ScanMenuPage extends StatefulWidget {
  const ScanMenuPage({super.key});

  @override
  State<ScanMenuPage> createState() => _ScanMenuPageState();
}

class _ScanMenuPageState extends State<ScanMenuPage> {
  String? _imagePath;
  XFile? _pickedFile;
  bool _isAnalyzing = false;
  String _statusMessage = "";
  List<FoodAnalysis>? _analysisResults;
  String _rawOcrText = "";
  String _aiResponseText = ""; // 保存AI原始响应用于调试

  // API配置
  static const String _ocrApiKey = 'K84726173688957';
  static const String _ocrUrl = 'https://api.ocr.space/parse/image';
  static const String _deepSeekKey = 'sk-a00b6f5bd699411f89701a26dced57d4';
  static const String _deepSeekUrl = 'https://api.deepseek.com/v1/chat/completions';

  // 选择图片
  Future<void> _pickImage(ImageSource source) async {
    _debugPrint('PICK', '开始选择图片，来源: ${source == ImageSource.camera ? "相机" : "相册"}');

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _debugPrint('PICK', '图片选择成功: ${pickedFile.path}');
        _debugPrint('PICK', '文件名: ${pickedFile.name}, 大小: ${pickedFile.length()}');

        setState(() {
          _imagePath = pickedFile.path;
          _pickedFile = pickedFile;
          _analysisResults = null;
          _rawOcrText = "";
          _aiResponseText = "";
          _statusMessage = "图片准备完成，建议拍摄菜单清晰照片";
        });
      } else {
        _debugPrint('PICK', '用户取消选择');
      }
    } catch (e) {
      _debugPrint('PICK', '选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  // 开始分析
  Future<void> _startAnalysis() async {
    if (_pickedFile == null) {
      _debugPrint('ANALYSIS', '错误: 没有选中的图片');
      return;
    }

    _debugPrint('ANALYSIS', '========== 开始分析流程 ==========');
    _debugPrint('ANALYSIS', '图片路径: $_imagePath');
    _debugPrint('ANALYSIS', '是否为Web: $kIsWeb');

    setState(() {
      _isAnalyzing = true;
      _statusMessage = "正在识别分析中，请耐心等待...";
    });

    try {
      // 步骤1: 读取文件字节
      _debugPrint('ANALYSIS', '步骤1: 读取图片字节...');
      Uint8List imageBytes;

      if (kIsWeb) {
        // Web端：使用http请求读取blob URL
        _debugPrint('ANALYSIS', 'Web端，使用http请求读取图片...');
        try {
          final response = await http.get(Uri.parse(_pickedFile!.path));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            imageBytes = response.bodyBytes;
            _debugPrint('ANALYSIS', 'Web端图片读取成功，大小: ${imageBytes.length} 字节');
          } else {
            throw Exception('Web端图片读取失败，状态码: ${response.statusCode}');
          }
        } catch (e) {
          _debugPrint('ANALYSIS', 'Web端http读取失败，尝试备用方法: $e');
          // 备用方法：使用XFile自带的读取方式
          imageBytes = await _pickedFile!.readAsBytes();
        }
      } else {
        // 移动端：直接读取文件
        imageBytes = await _pickedFile!.readAsBytes();
      }

      _debugPrint('ANALYSIS', '图片最终大小: ${imageBytes.length} 字节');

      // 验证图片大小
      if (imageBytes.length < 1000) {
        _debugPrint('ANALYSIS', '警告: 图片过小 (${imageBytes.length} 字节)，可能导致OCR失败');
      }

      // 步骤2: 调用OCR
      _debugPrint('ANALYSIS', '步骤2: 调用OCR识别...');
      String ocrText = await _recognizeTextFromImage(imageBytes);
      _rawOcrText = ocrText;

      _debugPrint('ANALYSIS', 'OCR原始结果长度: ${ocrText.length} 字符');
      if (ocrText.length <= 200) {
        _debugPrint('ANALYSIS', 'OCR结果: "$ocrText"');
      } else {
        _debugPrint('ANALYSIS', 'OCR结果前200字: "${ocrText.substring(0, 200)}..."');
      }

      if (ocrText.startsWith('Error') ||
          ocrText.startsWith('OCR Error') ||
          ocrText.startsWith('OCR Exception') ||
          ocrText.trim().isEmpty) {
        _debugPrint('ANALYSIS', 'OCR识别失败: $ocrText');
        throw Exception("OCR识别失败: $ocrText");
      }

      setState(() {
        _statusMessage = "OCR识别成功，AI正在分析营养成分...";
      });

      // 步骤3: 调用AI分析
      _debugPrint('ANALYSIS', '步骤3: 调用AI分析...');
      List<FoodAnalysis> results = await _analyzeFoodWithAI(ocrText);
      _debugPrint('ANALYSIS', 'AI分析完成，识别到 ${results.length} 种食物');

      setState(() {
        _analysisResults = results;
        _statusMessage = "分析完成！共识别 ${results.length} 种食物";
      });

      _debugPrint('ANALYSIS', '========== 分析流程结束 ==========');
    } catch (e, stackTrace) {
      _debugPrint('ANALYSIS', '分析过程异常: $e');
      _debugPrint('ANALYSIS', '堆栈跟踪: $stackTrace');
      setState(() {
        _statusMessage = "分析失败：$e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // 保存到数据库
  Future<void> _saveFoods() async {
    if (_analysisResults == null || _analysisResults!.isEmpty) {
      _debugPrint('SAVE', '没有分析结果需要保存');
      return;
    }

    _debugPrint('SAVE', '开始保存 ${_analysisResults!.length} 条饮食记录');

    try {
      for (var food in _analysisResults!) {
        _debugPrint('SAVE', '保存食物: ${food.foodName}');
        await DatabaseService.addFoodAnalysis(food);
      }

      _debugPrint('SAVE', '保存成功');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 保存成功！已添加 ${_analysisResults!.length} 条饮食记录')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _debugPrint('SAVE', '保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 保存失败：$e')),
        );
      }
    }
  }

  // OCR文字识别
  Future<String> _recognizeTextFromImage(Uint8List imageBytes) async {
    _debugPrint('OCR', '开始OCR识别...');
    _debugPrint('OCR', '图片大小: ${imageBytes.length} 字节');

    try {
      // 检测图片格式并设置正确的MIME类型
      String mimeType = 'image/jpeg'; // 默认
      String base64Prefix = 'data:image/jpeg;base64,';

      if (imageBytes.length >= 8) {
        // 检测PNG magic number
        if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
          mimeType = 'image/png';
          base64Prefix = 'data:image/png;base64,';
          _debugPrint('OCR', '检测到PNG格式');
        }
        // 检测JPEG magic number
        else if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
          mimeType = 'image/jpeg';
          base64Prefix = 'data:image/jpeg;base64,';
          _debugPrint('OCR', '检测到JPEG格式');
        }
      }

      String base64Image = base64Encode(imageBytes);
      // 添加正确的前缀格式
      String base64WithPrefix = '$base64Prefix$base64Image';
      _debugPrint('OCR', 'Base64编码完成，长度: ${base64Image.length}');

      // 检查图片大小
      if (imageBytes.length > 4 * 1024 * 1024) {
        _debugPrint('OCR', '警告: 图片超过4MB，可能导致OCR失败');
      }

      _debugPrint('OCR', '发送OCR请求到 $_ocrUrl');

      final response = await http.post(
        Uri.parse(_ocrUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apikey": _ocrApiKey,
          "base64image": base64WithPrefix, // 添加MIME类型前缀
          "language": "chs",
          "isOverlayRequired": "false",
          "scale": "true",
          "detectOrientation": "true",
          "OCREngine": "2",
        },
      );

      _debugPrint('OCR', 'HTTP状态码: ${response.statusCode}');
      _debugPrint('OCR', '响应长度: ${response.body.length} 字符');

      if (response.statusCode != 200) {
        _debugPrint('OCR', 'OCR请求失败，状态码: ${response.statusCode}');
        return 'OCR请求失败: ${response.statusCode}';
      }

      // 解析响应
      final Map<String, dynamic> data = jsonDecode(response.body);
      _debugPrint('OCR', '响应JSON解析成功');
      _debugPrint('OCR', 'IsErroredOnProcessing: ${data['IsErroredOnProcessing']}');

      if (data['IsErroredOnProcessing'] == true) {
        final errorMsg = data['ErrorMessage']?.toString() ?? '未知错误';
        _debugPrint('OCR', 'OCR处理错误: $errorMsg');
        return 'OCR处理错误: $errorMsg';
      }

      final parsedResults = data['ParsedResults'] as List?;
      _debugPrint('OCR', 'ParsedResults数量: ${parsedResults?.length ?? 0}');

      if (parsedResults == null || parsedResults.isEmpty) {
        _debugPrint('OCR', '警告: OCR返回空结果');
        return '';
      }

      String text = parsedResults[0]['ParsedText'] ?? '';
      _debugPrint('OCR', '提取文本长度: ${text.length}');

      final cleanedText = text.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      _debugPrint('OCR', '清理后文本长度: ${cleanedText.length}');

      return cleanedText;
    } catch (e, stackTrace) {
      _debugPrint('OCR', 'OCR异常: $e');
      _debugPrint('OCR', '堆栈跟踪: $stackTrace');
      return 'OCR异常: $e';
    }
  }

  // 使用AI分析食物营养
  Future<List<FoodAnalysis>> _analyzeFoodWithAI(String ocrText) async {
    _debugPrint('AI', '========== AI分析开始 ==========');
    _debugPrint('AI', '输入文本长度: ${ocrText.length} 字符');

    // 获取用户信息
    UserProfile profile = DatabaseService.getUserProfile();
    int recommendedCalories = _calculateRecommendedCalories(profile);

    _debugPrint('AI', '用户信息: 身高${profile.height}cm, 体重${profile.weight}kg, 推荐热量$recommendedCalories大卡');

    final userPrompt = """
请分析以下食物/菜谱文本，提取营养信息并给出建议。

食物文本：$ocrText

用户信息：
- 身高：${profile.height.toStringAsFixed(0)}cm
- 体重：${profile.weight.toStringAsFixed(1)}kg
- 每日推荐热量：$recommendedCalories 大卡

请以JSON格式返回分析结果，包含以下字段：
- foodName: 食物名称
- calories: 热量（如"约 300 大卡"）
- protein: 蛋白质含量（如"15g"）
- carbs: 碳水化合物含量（如"45g"）
- fat: 脂肪含量（如"12g"）
- suggestion: 健康建议（50字以内）

如果识别到多种食物，请用JSON数组返回。确保返回的是标准JSON格式。
""";

    _debugPrint('AI', '构建请求到 $_deepSeekUrl');

    final body = jsonEncode({
      "model": "deepseek-chat",
      "messages": [
        {
          "role": "system",
          "content": "你是一位专业的营养师，擅长分析食物营养成分。你只输出标准的JSON格式数据。"
        },
        {"role": "user", "content": userPrompt}
      ],
      "temperature": 0.1,
      "max_tokens": 2000,
      "response_format": {"type": "json_object"}
    });

    _debugPrint('AI', '发送AI请求...');

    try {
      final response = await http.post(
        Uri.parse(_deepSeekUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepSeekKey',
        },
        body: utf8.encode(body),
      );

      _debugPrint('AI', 'HTTP状态码: ${response.statusCode}');
      _debugPrint('AI', '响应长度: ${response.body.length} 字符');

      if (response.statusCode != 200) {
        final errorBody = utf8.decode(response.bodyBytes);
        _debugPrint('AI', '请求失败，响应: $errorBody');
        throw Exception('AI分析请求失败: ${response.statusCode}');
      }

      // 解析响应
      final decodedBody = utf8.decode(response.bodyBytes);
      _debugPrint('AI', '响应解码成功');

      final jsonResponse = jsonDecode(decodedBody);
      String content = jsonResponse['choices'][0]['message']['content'];

      // 保存原始响应用于调试
      _aiResponseText = content;
      _debugPrint('AI', 'AI响应长度: ${content.length} 字符');

      if (content.length <= 500) {
        _debugPrint('AI', 'AI响应: "$content"');
      } else {
        _debugPrint('AI', 'AI响应前500字: "${content.substring(0, 500)}..."');
      }

      // 清理Markdown标记
      content = content.replaceAll("```json", "").replaceAll("```", "").trim();
      _debugPrint('AI', '清理Markdown后长度: ${content.length}');

      try {
        // 尝试解析为JSON数组
        final List<dynamic> foods = jsonDecode(content);
        _debugPrint('AI', '解析为数组成功，元素数量: ${foods.length}');

        final results = foods.map((f) => FoodAnalysis.fromJson(f)).toList();

        for (var i = 0; i < results.length; i++) {
          _debugPrint('AI', '食物${i + 1}: ${results[i].foodName}, 热量: ${results[i].calories}');
        }

        return results;
      } catch (e) {
        _debugPrint('AI', '数组解析失败，尝试解析为单个对象: $e');

        // 尝试解析为单个对象
        final food = FoodAnalysis.fromJson(jsonDecode(content));
        _debugPrint('AI', '解析成功: ${food.foodName}, 热量: ${food.calories}');

        return [food];
      }
    } catch (e, stackTrace) {
      _debugPrint('AI', 'AI分析异常: $e');
      _debugPrint('AI', '堆栈跟踪: $stackTrace');
      throw Exception('AI分析失败: $e');
    }
  }

  int _calculateRecommendedCalories(UserProfile profile) {
    double bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5;
    double activityFactor = 1.3;
    return (bmr * activityFactor).round();
  }

  // 构建图片预览
  Widget _buildImagePreview() {
    if (_imagePath != null) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? Image.network(
                  _imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    _debugPrint('IMAGE', 'Web图片加载失败: $error');
                    return _buildImageErrorWidget();
                  },
                )
              : Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    _debugPrint('IMAGE', '本地图片加载失败: $error');
                    return _buildImageErrorWidget();
                  },
                ),
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("请拍摄菜单或食物照片", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text("图片加载失败", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 构建单个食物营养卡片
  Widget _buildFoodCard(FoodAnalysis food) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    food.foodName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildNutriRow("热量", food.calories),
            _buildNutriRow("蛋白质", food.protein),
            _buildNutriRow("碳水化合物", food.carbs),
            _buildNutriRow("脂肪", food.fat),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      food.suggestion,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutriRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 显示调试信息的对话框
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('调试信息'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('OCR 原始文本:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _rawOcrText.isEmpty ? '(无)' : _rawOcrText,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text('AI 原始响应:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _aiResponseText.isEmpty ? '(无)' : _aiResponseText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("菜谱营养分析"),
        actions: [
          // 调试按钮（仅在调试模式显示）
          if (_kEnableDebug && (_rawOcrText.isNotEmpty || _aiResponseText.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugInfo,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图片预览区
              _buildImagePreview(),

              const SizedBox(height: 20),

              // 状态提示
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      if (_isAnalyzing)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 操作按钮区
              if (!_isAnalyzing && _analysisResults == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("拍照上传"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("从相册选择"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),

              // 开始分析按钮
              if (_pickedFile != null && !_isAnalyzing && _analysisResults == null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _startAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "开始分析",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

              // 分析结果展示
              if (_analysisResults != null && _analysisResults!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "营养分析结果",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._analysisResults!.map((food) => _buildFoodCard(food)).toList(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveFoods,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              "保存记录",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                                _pickedFile = null;
                                _analysisResults = null;
                                _statusMessage = "";
                                _rawOcrText = "";
                                _aiResponseText = "";
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text("重新扫描"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
