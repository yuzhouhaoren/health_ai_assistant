import 'package:flutter/material.dart';
import '../pages/diet_analysis_page.dart';

class AppRoutes {
  /// 路由映射表：页面名称 → 页面构建函数
  static Map<String, WidgetBuilder> get routes => {
    DietAnalysisPage.routeName: (context) => const DietAnalysisPage(),
  };
}