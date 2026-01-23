import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/ocr_utils.dart';
import '../utils/deepseek_utils.dart';

class DietAnalysisPage extends StatefulWidget {
  /// 路由名称
  static const String routeName = '/diet_analysis';

  const DietAnalysisPage({super.key});

  @override
  State<DietAnalysisPage> createState() => _DietAnalysisPageState();
}

class _DietAnalysisPageState extends State<DietAnalysisPage> {
  // 核心实例
  final ImagePicker _picker = ImagePicker();

  // 状态管理
  XFile? _selectedImage; // 选中的图片
  bool _isAnalyzing = false; // 分析中状态
  String? _errorMessage; // 错误提示
  Map<String, dynamic>? _analysisResult; // 分析结果

  /// 选择饮食图片（从相册）
  Future<void> _pickDietImage() async {
    setState(() {
      _isAnalyzing = false;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      setState(() => _errorMessage = "选图失败：${e.toString()}");
    }
  }

  /// 执行饮食分析（OCR + DeepSeek）
  Future<void> _analyzeDiet() async {
    // 校验：未选图直接返回
    if (_selectedImage == null) {
      setState(() => _errorMessage = "请先选择饮食图片！");
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // 步骤1：OCR 识别图片中的饮食信息
      String? dietText = await OcrUtils.recognizeDietInfo(_selectedImage!);
      if (dietText == null) throw Exception("OCR 识别失败");

      // 步骤2：DeepSeek AI 分析营养数据
      Map<String, dynamic>? result = await DeepSeekUtils.analyzeDiet(dietText);
      if (result == null) throw Exception("AI 分析失败");

      // 步骤3：更新结果
      setState(() => _analysisResult = result);
    } catch (e) {
      setState(() => _errorMessage = "分析失败：${e.toString()}");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  /// 清除所有数据
  void _clearData() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  /// 构建图片预览（适配 Web/移动端）
  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return const SizedBox(
        width: 300,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("未选择饮食图片", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    Widget imageContent = kIsWeb
        ? Image.network(_selectedImage!.path, width: 300, height: 300, fit: BoxFit.cover)
        : Image.file(File(_selectedImage!.path), width: 300, height: 300, fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageContent,
    );
  }

  /// 构建分析结果展示
  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📊 饮食分析结果", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Text("菜品类型：${_analysisResult!["food_type"]}"),
          Text("热量：${_analysisResult!["calorie"]}"),
          const SizedBox(height: 10),
          const Text("营养成分：", style: TextStyle(fontWeight: FontWeight.w500)),
          ...(_analysisResult!["nutrition"] as Map<String, dynamic>).entries
              .map((entry) => Text("• ${entry.key}：${entry.value}"))
              .toList(),
          const SizedBox(height: 10),
          Text("💡 建议：${_analysisResult!["suggestion"]}", style: TextStyle(color: Colors.blueAccent)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("饮食分析"),
        centerTitle: true,
        actions: [IconButton(onPressed: _clearData, icon: const Icon(Icons.clear))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图片预览
            _buildImagePreview(),
            const SizedBox(height: 20),

            // 功能按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickDietImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("选择饮食图片"),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeDiet,
                  icon: _isAnalyzing
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.analytics),
                  label: const Text("开始分析"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),

            // 错误提示
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // 分析结果
            _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }
}