import 'package:flutter/material.dart';

class ScanMedicinePage extends StatelessWidget {
  const ScanMedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('药品识别'),
        // 返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              '药品识别页面',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              '模块一：开发中...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}