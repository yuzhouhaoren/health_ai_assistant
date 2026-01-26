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
import 'news_service.dart';

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
    try {
      List<FoodAnalysis> foods = DatabaseService.getFoodAnalysis();

      // 筛选今日饮食记录
      final now = DateTime.now();
      final todayFoods = foods.where((food) =>
          food.analyzedAt.year == now.year &&
          food.analyzedAt.month == now.month &&
          food.analyzedAt.day == now.day
      ).toList();

      if (todayFoods.isEmpty) {
        return "未记录饮食";
      }

      // 累加卡路里
      int totalCalories = 0;
      for (var food in todayFoods) {
        totalCalories += _extractCalories(food.calories);
      }

      // 获取用户信息计算推荐值
      UserProfile profile = DatabaseService.getUserProfile();
      int recommendedCalories = _calculateRecommendedCalories(profile);

      return "约 $totalCalories 大卡 (推荐 $recommendedCalories 大卡)";
    } catch (e) {
      return "获取失败";
    }
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
  static Future<String> getHealthTimeline() async {
    try {
      // 获取用户数据
      UserProfile profile = DatabaseService.getUserProfile();
      List<Medicine> medicines = DatabaseService.getMedicines();
      List<FoodAnalysis> foods = DatabaseService.getFoodAnalysis();

      // 获取当前时间
      final now = DateTime.now();
      String currentTime = DateFormat('HH:mm').format(now);
      String greeting = _getGreeting(now.hour);

      // 获取今日饮食
      final todayFoods = foods.where((food) =>
          food.analyzedAt.year == now.year &&
          food.analyzedAt.month == now.month &&
          food.analyzedAt.day == now.day
      ).toList();

      // 计算今日已摄入卡路里
      int consumedCalories = 0;
      for (var food in todayFoods) {
        consumedCalories += _extractCalories(food.calories);
      }

      // 构建用户信息描述
      String userInfo = """
用户信息：
- 姓名：${profile.name}
- 年龄：${profile.age}岁
- 身高：${profile.height.toStringAsFixed(0)}cm
- 体重：${profile.weight.toStringAsFixed(1)}kg
- BMI：${profile.bmi.toStringAsFixed(1)}（${profile.bmiStatus}）
- 今日已摄入卡路里：$consumedCalories 大卡
""";

      // 构建药物信息
      String medInfo = medicines.isNotEmpty
          ? medicines.map((m) => "- ${m.name}，每次${m.dose}，${m.frequency}").join("\n")
          : "无服药记录";

      // 构建Prompt
      String prompt = """
$userInfo

当前时间：${currentTime}（$greeting）

今日服药计划：
$medInfo

请根据以上信息，生成一条简短实用的个性化健康建议（100字以内），包括：
1. 当前时间段的养生建议（如饮食、运动、作息）
2. 服药提醒（如有）
3. 针对用户BMI的提醒（如有）

请用温暖的语气表达，像一个贴心的健康管家。
""";

      String aiResponse = await ApiService.askAI(
          "你是一个专业的健康管家，擅长根据用户的身体状况和时间提供个性化建议。",
          prompt
      );

      // 格式化输出
      return "现在是 $currentTime $greeting\n\n$aiResponse";
    } catch (e) {
      return "现在是 ${_getCurrentTime()}，获取健康建议失败";
    }
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
  /// [!计分标准] 根据BMI、饮食记录、服药依从性计算
  /// [!实现步骤]
  ///   1. 获取用户各项健康数据
  ///   2. 根据计分标准计算每项得分
  ///   3. 计算总分并生成评价
  /// [!输入参数] 无
  /// [!返回格式] 字符串，如："92分 - 优秀！继续保持"
  static String getHealthScore() {
    try {
      // 获取用户数据
      UserProfile profile = DatabaseService.getUserProfile();
      List<Medicine> medicines = DatabaseService.getMedicines();
      List<FoodAnalysis> foods = DatabaseService.getFoodAnalysis();

      // 计算BMI得分（满分30分）
      double bmi = profile.bmi;
      int bmiScore;
      if (bmi >= 18.5 && bmi <= 23.9) {
        bmiScore = 30;  // 正常BMI
      } else if (bmi >= 24 && bmi <= 27.9) {
        bmiScore = 20;  // 偏胖
      } else if (bmi < 18.5) {
        bmiScore = 15;  // 偏瘦
      } else {
        bmiScore = 10;  // 肥胖
      }

      // 计算饮食得分（满分30分）
      final now = DateTime.now();
      final todayFoods = foods.where((food) =>
          food.analyzedAt.year == now.year &&
          food.analyzedAt.month == now.month &&
          food.analyzedAt.day == now.day
      ).toList();

      int foodScore = 0;
      if (todayFoods.isEmpty) {
        foodScore = 15;  // 未记录饮食，基础分
      } else {
        int consumedCalories = 0;
        for (var food in todayFoods) {
          consumedCalories += _extractCalories(food.calories);
        }
        int recommended = _calculateRecommendedCalories(profile);
        double calorieRatio = consumedCalories / recommended;

        if (calorieRatio >= 0.8 && calorieRatio <= 1.2) {
          foodScore = 30;  // 饮食正常
        } else if (calorieRatio >= 0.6 && calorieRatio < 0.8) {
          foodScore = 25;  // 略少
        } else if (calorieRatio > 1.2 && calorieRatio <= 1.5) {
          foodScore = 25;  // 略多
        } else if (calorieRatio < 0.6) {
          foodScore = 15;  // 太少
        } else {
          foodScore = 10;  // 太多
        }
      }

      // 计算服药得分（满分30分）
      int medScore = 0;
      if (medicines.isEmpty) {
        medScore = 30;  // 无需服药，满分
      } else {
        // 检查今日是否按时服药
        int takenCount = 0;
        int totalCount = 0;

        for (var med in medicines) {
          totalCount += med.schedule.length;
          for (var timeStr in med.schedule) {
            try {
              List<String> parts = timeStr.trim().split(":");
              if (parts.length >= 2) {
                int h = int.parse(parts[0]);
                int m = int.parse(parts[1]);
                DateTime scheduleTime = DateTime(now.year, now.month, now.day, h, m);
                // 如果当前时间超过服药时间30分钟，且有服药记录，则视为已服药
                if (now.isAfter(scheduleTime.add(const Duration(minutes: 30))) ||
                    med.lastTaken != null && med.lastTaken!.isAfter(scheduleTime)) {
                  takenCount++;
                }
              }
            } catch (e) {
              continue;
            }
          }
        }

        if (totalCount == 0) {
          medScore = 30;
        } else {
          double adherenceRate = takenCount / totalCount;
          if (adherenceRate >= 0.8) {
            medScore = 30;
          } else if (adherenceRate >= 0.6) {
            medScore = 25;
          } else {
            medScore = 15;
          }
        }
      }

      // 计算作息得分（满分10分）
      int scheduleScore = _calculateScheduleScore(now.hour);

      // 总分
      int totalScore = bmiScore + foodScore + medScore + scheduleScore;

      // 生成评价
      String evaluation;
      if (totalScore >= 90) {
        evaluation = "优秀！继续保持";
      } else if (totalScore >= 75) {
        evaluation = "良好，还有提升空间";
      } else if (totalScore >= 60) {
        evaluation = "一般，请注意健康";
      } else {
        evaluation = "较差，需要改善";
      }

      return "$totalScore分 - $evaluation\n"
          "（BMI ${bmiScore}分 + 饮食 ${foodScore}分 + 服药 ${medScore}分 + 作息 ${scheduleScore}分）";
    } catch (e) {
      return "计算失败";
    }
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
  /// [辅助函数] 获取当前时间（HH:mm格式）
  /// [!功能] 返回格式化的当前时间字符串
  /// [!返回] 如："15:30"
  static String _getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// [辅助函数] 从字符串提取卡路里数值
  /// [!功能] 从"约 300 大卡"中提取数字300
  /// [!参数] caloriesString: 卡路里字符串
  /// [!返回] 整数值
  static int _extractCalories(String caloriesString) {
    try {
      // 匹配数字
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(caloriesString);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// [辅助函数] 根据时间段获取问候语
  /// [!参数] hour: 24小时制的小时数
  /// [!返回] 问候语
  static String _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return "早上好";
    } else if (hour >= 12 && hour < 14) {
      return "中午好";
    } else if (hour >= 14 && hour < 18) {
      return "下午好";
    } else if (hour >= 18 && hour < 22) {
      return "晚上好";
    } else {
      return "夜深了";
    }
  }

  /// [辅助函数] 计算推荐每日卡路里摄入量
  /// [!基于] 静息代谢率 + 活动系数
  /// [!参数] profile: 用户资料
  /// [!返回] 推荐每日卡路里（大卡）
  static int _calculateRecommendedCalories(UserProfile profile) {
    // 基础代谢率计算（使用Mifflin-St Jeor公式）
    double bmr;
    if (profile.age > 0) {
      // 男性: 10×体重(kg) + 6.25×身高(cm) - 5×年龄 + 5
      // 女性: 10×体重(kg) + 6.25×身高(cm) - 5×年龄 - 161
      bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5;
    } else {
      bmr = 10 * profile.weight + 6.25 * profile.height + 5;
    }

    // 根据BMI调整活动系数
    double activityFactor;
    double bmi = profile.bmi;

    if (bmi < 18.5) {
      activityFactor = 1.2;  // 偏瘦，需要增重，较低活动
    } else if (bmi >= 18.5 && bmi < 24) {
      activityFactor = 1.5;  // 正常体重，标准活动
    } else if (bmi >= 24 && bmi < 28) {
      activityFactor = 1.3;  // 偏胖，适当控制
    } else {
      activityFactor = 1.15;  // 肥胖，减重为主
    }

    return (bmr * activityFactor).round();
  }

  /// [辅助函数] 根据当前时间计算作息得分
  /// [!参数] hour: 当前小时
  /// [!返回] 得分（0-10分）
  static int _calculateScheduleScore(int hour) {
    // 理想作息时间表
    if (hour >= 6 && hour <= 9) {
      return 10;  // 早起时段，加分
    } else if (hour >= 9 && hour <= 12) {
      return 8;   // 上午
    } else if (hour >= 12 && hour <= 14) {
      return 8;   // 午休时段
    } else if (hour >= 14 && hour <= 18) {
      return 8;   // 下午
    } else if (hour >= 18 && hour <= 21) {
      return 7;   // 晚上
    } else if (hour >= 21 && hour <= 23) {
      return 6;   // 晚睡边缘
    } else {
      return 4;   // 深夜熬夜
    }
  }

  // ==================== 健康新闻模块 ====================

  /// [函数6] 获取健康新闻
  /// ============================================
  /// [!功能描述] 获取每日健康新闻（2条）
  /// [!实现步骤]
  ///   1. 调用NewsService获取新闻
  ///   2. 格式化返回结果
  /// [!输入参数] 无
  /// [!返回格式] Future<List<HealthNews>>
  static Future<List<HealthNews>> getHealthNews() async {
    try {
      return await NewsService.getHealthNews();
    } catch (e) {
      // 如果获取失败，返回空列表
      return [];
    }
  }
}
