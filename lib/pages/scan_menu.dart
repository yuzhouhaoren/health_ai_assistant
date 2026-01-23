import 'package:flutter/material.dart';

class ScanMenuPage extends StatelessWidget {
  const ScanMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜谱分析'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              '菜谱分析页面',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              '模块二：开发中...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}