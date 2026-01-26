import 'package:flutter/material.dart';
import '../services/database.dart';
import '../models/food.dart';

class TodayMenuPage extends StatefulWidget {
  const TodayMenuPage({super.key});

  @override
  State<TodayMenuPage> createState() => _TodayMenuPageState();
}

class _TodayMenuPageState extends State<TodayMenuPage> {
  List<FoodAnalysis> _todayFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayFoods();
  }

  Future<void> _loadTodayFoods() async {
    await DatabaseService.init();
    setState(() {
      _isLoading = true;
    });

    try {
      List<FoodAnalysis> allFoods = DatabaseService.getFoodAnalysis();
      final now = DateTime.now();

      // 筛选今日饮食记录
      _todayFoods = allFoods.where((food) =>
          food.analyzedAt.year == now.year &&
          food.analyzedAt.month == now.month &&
          food.analyzedAt.day == now.day
      ).toList();

      // 按时间倒序排列
      _todayFoods.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    } catch (e) {
      debugPrint('加载今日菜谱失败: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 计算今日总卡路里
  int _calculateTotalCalories() {
    int total = 0;
    for (var food in _todayFoods) {
      total += _extractCalories(food.calories);
    }
    return total;
  }

  int _extractCalories(String caloriesString) {
    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日菜谱'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_todayFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '今日暂无菜谱记录',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮开始记录今日饮食',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('开始记录'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡片
            _buildStatisticsCard(),
            const SizedBox(height: 16),

            // 菜谱列表标题
            Row(
              children: [
                const Icon(Icons.list, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '今日记录 (${_todayFoods.length}项)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 菜谱列表
            ..._todayFoods.map((food) => _buildFoodCard(food)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    int totalCalories = _calculateTotalCalories();
    UserProfile profile = DatabaseService.getUserProfile();
    int recommended = _calculateRecommendedCalories(profile);
    double progress = recommended > 0 ? (totalCalories / recommended).clamp(0.0, 1.5) : 0;

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '今日热量统计',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 热量进度条
            Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress > 1 ? 1 : progress,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: progress > 1 ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已摄入: $totalCalories 大卡',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '推荐: $recommended 大卡',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 营养素概览
            Row(
              children: [
                _buildNutrientChip('蛋白质', _calculateTotalProtein()),
                const SizedBox(width: 8),
                _buildNutrientChip('碳水', _calculateTotalCarbs()),
                const SizedBox(width: 8),
                _buildNutrientChip('脂肪', _calculateTotalFat()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
      ),
    );
  }

  String _calculateTotalProtein() {
    int total = 0;
    for (var food in _todayFoods) {
      try {
        RegExp regExp = RegExp(r'(\d+)');
        Match? match = regExp.firstMatch(food.protein);
        if (match != null) {
          total += int.parse(match.group(1)!);
        }
      } catch (e) {}
    }
    return '${total}g';
  }

  String _calculateTotalCarbs() {
    int total = 0;
    for (var food in _todayFoods) {
      try {
        RegExp regExp = RegExp(r'(\d+)');
        Match? match = regExp.firstMatch(food.carbs);
        if (match != null) {
          total += int.parse(match.group(1)!);
        }
      } catch (e) {}
    }
    return '${total}g';
  }

  String _calculateTotalFat() {
    int total = 0;
    for (var food in _todayFoods) {
      try {
        RegExp regExp = RegExp(r'(\d+)');
        Match? match = regExp.firstMatch(food.fat);
        if (match != null) {
          total += int.parse(match.group(1)!);
        }
      } catch (e) {}
    }
    return '${total}g';
  }

  int _calculateRecommendedCalories(UserProfile profile) {
    double bmr = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5;
    double activityFactor = 1.3;
    return (bmr * activityFactor).round();
  }

  Widget _buildFoodCard(FoodAnalysis food) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    food.foodName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatTime(food.analyzedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const Divider(),

            // 营养信息
            Row(
              children: [
                _buildNutriInfo('热量', food.calories),
                _buildNutriInfo('蛋白质', food.protein),
                _buildNutriInfo('碳水', food.carbs),
                _buildNutriInfo('脂肪', food.fat),
              ],
            ),

            // 建议
            if (food.suggestion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        food.suggestion,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutriInfo(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
