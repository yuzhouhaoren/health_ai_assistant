import 'package:flutter/material.dart';
import '../pages/diet_analysis_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    DietAnalysisPage.routeName: (context) => const DietAnalysisPage(),
  };
}