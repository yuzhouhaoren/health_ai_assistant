import 'package:flutter/material.dart';
import 'services/database.dart';
import 'pages/home_page.dart';
// 页面导入保留，供跳转使用
import 'pages/scan_medicine.dart';
import 'pages/scan_menu.dart';
import 'pages/chat_page.dart';

void main() async {
  // 确保Flutter框架初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  try {
    await DatabaseService.init();
    print('应用启动：数据库初始化成功');
  } catch (e) {
    print('数据库初始化失败: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康AI管家',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 最简单的配置：只设置首页，不用routes
      home: const HomePage(),
    );
  }
}