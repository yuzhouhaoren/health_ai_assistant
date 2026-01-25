// home_functions.dart - 主页功能框架文件
// ====================================================
// [!重要说明] 这个文件包含5个框架函数，对应主页的5个模块
// [!开发指南] 其他开发者需要根据TODO注释实现具体逻辑
// [!注意事项] 1. 所有函数必须返回字符串
// [!注意事项] 2. 可以使用现有的 DatabaseService 和 ApiService
// [!注意事项] 3. 每个函数有详细的输入输出说明

import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/food.dart';
import 'database.dart';
import 'api_service.dart';

class HomeFunctions {
  // ==================== 模块1相关函数 ====================

  /// [函数1.1] 获取今日卡路里摄入
  /// ============================================
  /// [!功能描述] 计算今日正餐摄入的总卡路里
  /// [!数据来源] 从数据库获取今日所有菜谱记录
  /// [!实现步骤]
  ///   1. 调用 DatabaseService.getFoodAnalysis() 获取今日饮食
  ///   2. 从每个 FoodAnalysis 对象中提取 calories 字段
  ///   3. 将卡路里字符串转换为数字并累加
  ///   4. 格式化输出结果
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："约 1200 大卡" 或 "未记录饮食"
  static String getTodayCalories() {
    return "待开发中...";
  }

  /// [函数1.2] 获取今日需服药物
  /// ============================================
  /// [!功能描述] 列出今日需要服用的所有药物及时间
  /// [!数据来源] 从数据库获取所有药品，根据schedule判断
  /// [!实现步骤]
  ///   1. 调用 DatabaseService.getMedicines() 获取所有药品
  ///   2. 检查每个药品的 schedule 是否包含今天的时间
  ///   3. 格式化药品名称和服用时间
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："降压药(08:00,20:00)、维生素C(12:00)" 或 "今日无服药计划"
  static String getTodayMedicines() {
    try {
      List<Medicine> medicines = DatabaseService.getMedicines();
      if (medicines.isEmpty) {
        return "今日暂无服药计划";
      }

      List<String> displayList = [];
      for (var med in medicines) {
        String times = med.schedule.join(",");
        displayList.add("${med.name}($times)");
      }

      if (displayList.isEmpty) return "今日暂无服药计划";
      return displayList.join("、");
    } catch (e) {
      return "获取失败";
    }
  }

  // ==================== 模块2相关函数 ====================

  /// [函数2] 获取健康时间线建议
  /// ============================================
  /// [!功能描述] 根据当前时间生成个性化健康建议
  /// [!特别说明] 需要调用DeepSeek API生成自然语言建议
  /// [!实现步骤]
  ///   1. 获取当前时间（DateTime.now()）
  ///   2. 获取用户药品和饮食数据
  ///   3. 构建Prompt发送给DeepSeek API
  ///   4. 解析API返回的建议文本
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："现在是15:30，您可以开始锻炼啦！"
  static String getHealthTimeline() {
    // [!待实现区域] - 开发者需要在此添加具体逻辑
    // [!提示] 需要调用 ApiService 与 DeepSeek API 交互
    return "现在是 --:--，健康建议功能开发中";
  }

  // ==================== 模块3相关函数 ====================

  /// [函数3] 获取健康关联分析
  /// ============================================
  /// [!功能描述] 分析药品与食物的相互作用（冲突/促进）
  /// [!实现步骤]
  ///   1. 获取今日药品列表
  ///   2. 获取今日饮食记录
  ///   3. 检查常见药品-食物相互作用
  ///   4. 生成分析报告
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："注意：降压药与葡萄柚可能冲突" 或 "无已知相互作用"
  static Future<String> getInteractionAnalysis() async {
    try {
      List<Medicine> medicines = DatabaseService.getMedicines();
      List<FoodAnalysis> foods = DatabaseService.getFoodAnalysis();
      // 获取今天的食物
      final now = DateTime.now();
      final todayFoods = foods
          .where((food) =>
              food.analyzedAt.year == now.year &&
              food.analyzedAt.month == now.month &&
              food.analyzedAt.day == now.day)
          .toList();

      if (medicines.isEmpty && todayFoods.isEmpty) {
        return "今日暂无足够的药物和饮食记录进行分析。";
      }

      String medStr = medicines.map((m) => m.name).join(",");
      String foodStr = todayFoods.map((f) => f.foodName).join(",");

      String prompt = """
我正在服用药物：[$medStr]
我今天吃了食物：[$foodStr]
请分析是否存在任何已知的药物-食物相互作用（冲突或促进）。
如果有关联风险，请简明扼要地指出（主要冲突点）。
如果无明显风险，请回复"暂无发现明显相互作用风险"。
限制字数在50字以内。
""";

      return await ApiService.askAI("你是一个专业的药剂师和营养师。", prompt);
    } catch (e) {
      return "无法进行关联分析";
    }
  }

  // ==================== 模块4相关函数 ====================

  /// [函数4] 获取健康分数
  /// ============================================
  /// [!功能描述] 计算今日健康分数（初始分90）
  /// [!计分标准] 让AI来吧
  /// [!实现步骤]
  ///   1. 获取用户各项健康数据
  ///   2. 根据计分标准计算每项得分
  ///   3. 计算总分并生成评价
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："92分 - 优秀！继续保持"
  static String getHealthScore() {
    // [!待实现区域] - 开发者需要在此添加具体逻辑
    return "90分 - 分数计算功能开发中";
  }

  // ==================== 模块5相关函数 ====================

  ///[函数5]下次用要提醒
  /// ============================================
  /// [!功能描述] 计算下一个服药时间点
  /// [!实现步骤]
  ///   1. 获取所有药品的服药时间表
  ///   2. 计算下一个最近的服药时间
  ///   3. 考虑是否已服药
  ///   4. 格式化提醒信息
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："18:00 服用降压药，每次1片" 或 "今日服药已完成"
  static String getNextMedicine() {
    try {
      List<Medicine> medicines = DatabaseService.getMedicines();
      if (medicines.isEmpty) {
        return "无服药计划";
      }

      final now = DateTime.now();
      List<Map<String, dynamic>> allSchedules = [];

      for (var med in medicines) {
        for (var timeStr in med.schedule) {
          try {
            List<String> parts = timeStr.trim().split(":");
            if (parts.length < 2) continue;
            int h = int.parse(parts[0]);
            int m = int.parse(parts[1]);

            DateTime scheduleTime =
                DateTime(now.year, now.month, now.day, h, m);

            // 如果时间已过，算明天的
            if (scheduleTime.isBefore(now)) {
              scheduleTime = scheduleTime.add(const Duration(days: 1));
            }

            allSchedules.add({
              "time": scheduleTime,
              "medicine": med,
            });
          } catch (e) {
            continue;
          }
        }
      }

      if (allSchedules.isEmpty) return "无待办服药";

      allSchedules.sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

      var next = allSchedules.first;
      Medicine med = next['medicine'];
      String timeDisplay = DateFormat('HH:mm').format(next['time']);
      String dayHint = (next['time'] as DateTime).day != now.day ? "明天 " : "";

      return "$dayHint$timeDisplay 服用${med.name}，${med.dose}";
    } catch (e) {
      return "提醒服务异常";
    }
  }

  // ==================== 辅助函数区域 ====================
  // [!说明] 以下辅助函数供上面主要函数调用，也需要开发者实现

  /// [辅助函数] 获取当前时间（HH:mm格式）
  /// [!功能] 返回格式化的当前时间字符串
  /// [!返回] 如："15:30"
  static String _getCurrentTime() {
    // [!待实现] - 开发者可以根据需要实现
    return "--:--";
  }

  /// [辅助函数] 从字符串提取卡路里数值
  /// [!功能] 从"约 300 大卡"中提取数字300
  /// [!参数] caloriesString: 卡路里字符串
  /// [!返回] 整数值
  static int _extractCalories(String caloriesString) {
    // [!待实现] - 开发者可以根据需要实现
    return 0;
  }
}
