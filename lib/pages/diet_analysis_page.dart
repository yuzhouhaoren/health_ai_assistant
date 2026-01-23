import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/ocr_utils.dart';
import '../utils/deepseek_utils.dart';
import '../db/diet_dao.dart';
import '../models/diet_record.dart';
import 'package:cross_file/cross_file.dart';
import 'package:camera_web/camera_web.dart';

class DietAnalysisPage extends StatefulWidget {
  static const String routeName = "/dietAnalysis";

  const DietAnalysisPage({super.key});

  @override
  State<DietAnalysisPage> createState() => _DietAnalysisPageState();
}

class _DietAnalysisPageState extends State<DietAnalysisPage> {
  File? _selectedImage;
  bool _isLoading = false;
  NutritionResult? _nutritionResult;
  String? _extractedIngredients;

  // 1. 从相册选择图片（Flutter Web适配）
  Future<void> _pickImageFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ["jpg", "jpeg", "png"],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _nutritionResult = null; // 重置结果
      });
    }
  }

  // 2. 拍照上传（Flutter Web适配）
  Future<void> _takePhoto() async {
    final XFile? photo = await CameraWeb.captureImage(); // CameraWeb已识别
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _nutritionResult = null; // 重置结果
      });
    }
  }

  // 3. 核心流程：识别食材+分析营养
  Future<void> _analyzeDiet() async {
    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "请先选择或拍摄菜谱图片");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 步骤1：OCR提取食材
      _extractedIngredients = await OcrUtils.extractIngredients(_selectedImage!);
      if (_extractedIngredients == null || _extractedIngredients!.isEmpty) {
        throw Exception("未能识别到食材，请重新上传图片");
      }

      // 步骤2：DeepSeek分析营养
      _nutritionResult = await DeepSeekUtils.analyzeIngredients(_extractedIngredients!);
      if (_nutritionResult == null) {
        throw Exception("营养分析失败，请重试");
      }

      // 步骤3：存储到数据库
      DietRecord record = DietRecord(
        ingredients: _extractedIngredients!,
        calories: _nutritionResult!.calories,
        nutrition: _nutritionResult!.nutrition,
        suitableFor: _nutritionResult!.suitableFor,
        advice: _nutritionResult!.advice,
      );
      await DatabaseHelper.instance.insertDietRecord(record);
      Fluttertoast.showToast(msg: "饮食记录已保存");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      print("分析流程异常：$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("菜谱识别与饮食建议"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSelectionArea(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeDiet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading
              // 替换为flutter_spinkit的加载组件
                  ? const SpinKitBallSpinFadeLoader(
                color: Colors.white,
                size: 24,
              )
                  : const Text("开始识别与分析"),
            ),
            const SizedBox(height: 30),
            if (_nutritionResult != null) _buildResultArea(),
          ],
        ),
      ),
    );
  }

  // 图片选择/预览区域
  Widget _buildImageSelectionArea() {
    return Column(
      children: [
        // 图片预览
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _selectedImage != null
              ? Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
          )
              : const Center(child: Text("请选择或拍摄菜谱图片")),
        ),
        const SizedBox(height: 16),

        // 操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text("相册上传"),
            ),
            TextButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("拍照上传"),
            ),
          ],
        ),
      ],
    );
  }

  // 结果展示区域
  Widget _buildResultArea() {
    return Card(
      elevation: 4,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "识别结果",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),

          // 食材列表
          Text(
            "食材：${_extractedIngredients ?? '无'}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 热量
          Text(
            "总热量：${_nutritionResult!.calories}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 营养成分
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "主要营养成分：",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _nutritionResult!.nutrition
                    .map((nutri) => Chip(label: Text(nutri)))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 适合人群
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "适合人群：",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _nutritionResult!.suitableFor
                    .map((people) => Chip(label: Text(people)))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 健康建议
          Text(
            "健康建议：${_nutritionResult!.advice}",
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
        ],
      ),
    );
  }
}