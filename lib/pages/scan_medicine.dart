import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/database.dart';
import '../models/medicine.dart';

class ScanMedicinePage extends StatefulWidget {
  const ScanMedicinePage({super.key});

  @override
  State<ScanMedicinePage> createState() => _ScanMedicinePageState();
}

class _ScanMedicinePageState extends State<ScanMedicinePage> {
  String? _imagePath;
  XFile? _pickedFile;                    // 保存选择的文件对象
  bool _isAnalyzing = false;             // 判断是否在分析
  String _statusMessage = "";            // 显示状态提示
  Map<String, dynamic>? _analysisResult; // 存储分析结果
  String _rawOcrText = "";

  // 选择图片
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      // 压缩图片,限制最大宽度并降低质量，以确保文件大小小于1MB
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,       // 限制宽度
        imageQuality: 85,     // 压缩质量
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _pickedFile = pickedFile;
          _analysisResult = null;
          _rawOcrText = "";
          _statusMessage = "图片准备完成，建议横向拍摄，点击下方开始识别";
        });
      }
    } catch (e) {
      debugPrint("选择图片失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  // 开始分析
  Future<void> _startAnalysis() async {
    if (_pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = "正在上传分析中，请耐心等待...";
    });

    try {
      // 读取文件字节
      final Uint8List imageBytes = await _pickedFile!.readAsBytes();

      //调用OCR
      String ocrText = await ApiService.recognizeTextFromImage(imageBytes);
      _rawOcrText = ocrText;
      debugPrint("DEBUG OCR OUTPUT: $ocrText");

      // 检查OCR是否返回了错误信息
      if (ocrText.startsWith('Error') ||
          ocrText.startsWith('OCR Error') ||
          ocrText.startsWith('OCR Exception') ||
          ocrText.trim().isEmpty) {
        throw Exception("OCR识别失败: $ocrText");
      }

      setState(() {
        _statusMessage = "OCR识别成功，AI正在提取信息...";
      });

      //调用DeepSeek分析
      Map<String, dynamic> aiResult =
          await ApiService.analyzeMedicineInfo(ocrText);

      if (aiResult.isEmpty) {
        throw Exception("AI无法从文本中提取有效信息");
      }

      setState(() {
        _analysisResult = aiResult; // 显示结果
        _statusMessage = "分析完成！请确认信息";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "分析失败：$e";
      });
      debugPrint("分析过程异常: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // 保存到数据库
  Future<void> _saveMedicine() async {
    if (_analysisResult == null) return;

    try {
      // 将map转换为medicine对象
      Medicine newMedicine = Medicine.fromJson(_analysisResult!);

      // 保存
      await DatabaseService.addMedicine(newMedicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 药品添加成功！')),
        );
        Navigator.pop(context); // 返回到主页
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 保存失败：$e')),
        );
      }
    }
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
                )
              : Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
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
            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("请拍摄药品包装盒正面", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  // 构建单个结果行
  Widget _buildResultRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? "未识别")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("药品智能识别")),
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 操作按钮区 (未在分析且无结果时显示)
              if (!_isAnalyzing && _analysisResult == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("拍照上传"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("从相册选择"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),

              //开始分析按钮 (已选图片，未分析，无结果)
              if (_pickedFile != null &&
                  !_isAnalyzing &&
                  _analysisResult == null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _startAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "开始识别信息",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

              //分析结果展示
              if (_analysisResult != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "识别结果确认",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildResultRow("药品名称", _analysisResult!['name']),
                            _buildResultRow("服用剂量", _analysisResult!['dose']),
                            _buildResultRow(
                                "服用频率", _analysisResult!['frequency']),
                            // 处理可能为列表的 schedule
                            _buildResultRow(
                                "服药时间",
                                (_analysisResult!['schedule'] is List)
                                    ? (_analysisResult!['schedule'] as List)
                                        .join(", ")
                                    : _analysisResult!['schedule']?.toString()),
                            _buildResultRow("注意事项", _analysisResult!['notes']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveMedicine,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              "保存信息",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
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
                                _analysisResult = null;
                                _statusMessage = "";
                                _rawOcrText = "";
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
