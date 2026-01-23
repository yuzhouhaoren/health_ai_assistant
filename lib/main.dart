import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'pages/diet_analysis_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '饮食分析 App',
      // 修复主题配置：二选一提供颜色
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue, // 提供一个种子色生成完整配色方案
      ),
      initialRoute: DietAnalysisPage.routeName,
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const DietAnalysisPage(),
      ),
    );
  }
}