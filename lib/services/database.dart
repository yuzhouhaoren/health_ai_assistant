import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // 用于JSON转换
import '../models/medicine.dart';
import '../models/food.dart';

// 用户信息模型类
class UserProfile {
  String name;
  int age;
  double height;      // 身高（厘米）
  double weight;      // 体重（公斤）
  String avatarPath;  // 头像本地路径
  String? avatarUrl;  // 头像网络URL（可选）

  UserProfile({
    this.name = '用户',
    this.age = 25,
    this.height = 170.0,
    this.weight = 65.0,
    this.avatarPath = '',
    this.avatarUrl,
  });

  // 将用户信息转为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'avatarPath': avatarPath,
      'avatarUrl': avatarUrl,
    };
  }

  // 从JSON创建用户对象
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '用户',
      age: json['age'] ?? 25,
      height: (json['height'] ?? 170.0).toDouble(),
      weight: (json['weight'] ?? 65.0).toDouble(),
      avatarPath: json['avatarPath'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }

  // 计算BMI
  double get bmi {
    if (height <= 0) return 0;
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // 获取BMI状态描述
  String get bmiStatus {
    double bmiValue = bmi;
    if (bmiValue < 18.5) return '偏瘦';
    if (bmiValue < 24) return '正常';
    if (bmiValue < 28) return '偏胖';
    return '肥胖';
  }
}

class DatabaseService {
  // 存储键名常量
  static const String _medicinesKey = 'medicines';
  static const String _foodAnalysisKey = 'food_analysis';
  static const String _userProfileKey = 'user_profile';  // 用户信息存储键名
  
  static late SharedPreferences _prefs;

  // 1. 初始化数据库
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print('数据库初始化完成');
  }

  // 2. ========== 药品相关操作 ==========
  
  // 保存所有药品
  static Future<bool> saveMedicines(List<Medicine> medicines) async {
    try {
      // 将药品列表转为JSON字符串
      List<Map<String, dynamic>> medicinesJson = [];
      for (var medicine in medicines) {
        medicinesJson.add(medicine.toJson());
      }
      String jsonString = jsonEncode(medicinesJson);
      
      // 保存到本地
      return await _prefs.setString(_medicinesKey, jsonString);
    } catch (e) {
      print('保存药品错误: $e');
      return false;
    }
  }

  // 获取所有药品
  static List<Medicine> getMedicines() {
    try {
      final jsonString = _prefs.getString(_medicinesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];  // 如果没有数据，返回空列表
      }
      
      // 解析JSON字符串
      List<dynamic> jsonList = jsonDecode(jsonString);
      List<Medicine> medicines = [];
      
      for (var json in jsonList) {
        medicines.add(Medicine.fromJson(json));
      }
      
      return medicines;
    } catch (e) {
      print('读取药品错误: $e');
      return [];
    }
  }

  // 添加单个药品
  static Future<bool> addMedicine(Medicine medicine) async {
    List<Medicine> medicines = getMedicines();
    medicines.add(medicine);
    return await saveMedicines(medicines);
  }

  // 删除药品
  static Future<bool> deleteMedicine(String id) async {
    List<Medicine> medicines = getMedicines();
    medicines.removeWhere((medicine) => medicine.id == id);
    return await saveMedicines(medicines);
  }

  // 更新药品最后服药时间
  static Future<bool> updateMedicineLastTaken(String id) async {
    List<Medicine> medicines = getMedicines();
    int index = medicines.indexWhere((medicine) => medicine.id == id);
    
    if (index != -1) {
      medicines[index].lastTaken = DateTime.now();
      return await saveMedicines(medicines);
    }
    return false;
  }

  // 3. ========== 菜谱相关操作 ==========
  
  // 保存所有菜谱分析
  static Future<bool> saveFoodAnalysis(List<FoodAnalysis> foods) async {
    try {
      List<Map<String, dynamic>> foodsJson = [];
      for (var food in foods) {
        foodsJson.add(food.toJson());
      }
      String jsonString = jsonEncode(foodsJson);
      
      return await _prefs.setString(_foodAnalysisKey, jsonString);
    } catch (e) {
      print('保存菜谱错误: $e');
      return false;
    }
  }

  // 获取所有菜谱分析
  static List<FoodAnalysis> getFoodAnalysis() {
    try {
      final jsonString = _prefs.getString(_foodAnalysisKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      List<dynamic> jsonList = jsonDecode(jsonString);
      List<FoodAnalysis> foods = [];
      
      for (var json in jsonList) {
        foods.add(FoodAnalysis.fromJson(json));
      }
      
      return foods;
    } catch (e) {
      print('读取菜谱错误: $e');
      return [];
    }
  }

  // 添加菜谱分析
  static Future<bool> addFoodAnalysis(FoodAnalysis food) async {
    List<FoodAnalysis> foods = getFoodAnalysis();
    foods.add(food);
    return await saveFoodAnalysis(foods);
  }

  // 5. ========== 用户信息相关操作 ==========

  // 保存用户信息
  static Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      String jsonString = jsonEncode(profile.toJson());
      return await _prefs.setString(_userProfileKey, jsonString);
    } catch (e) {
      print('保存用户信息错误: $e');
      return false;
    }
  }

  // 获取用户信息（如果不存在则返回默认用户）
  static UserProfile getUserProfile() {
    try {
      final jsonString = _prefs.getString(_userProfileKey);
      if (jsonString == null || jsonString.isEmpty) {
        // 返回默认用户信息
        return UserProfile();
      }

      Map<String, dynamic> json = jsonDecode(jsonString);
      return UserProfile.fromJson(json);
    } catch (e) {
      print('读取用户信息错误: $e');
      return UserProfile();  // 出错时返回默认用户
    }
  }

  // 更新用户姓名
  static Future<bool> updateUserName(String name) async {
    UserProfile profile = getUserProfile();
    profile.name = name;
    return await saveUserProfile(profile);
  }

  // 更新用户年龄
  static Future<bool> updateUserAge(int age) async {
    UserProfile profile = getUserProfile();
    profile.age = age;
    return await saveUserProfile(profile);
  }

  // 更新用户身高
  static Future<bool> updateUserHeight(double height) async {
    UserProfile profile = getUserProfile();
    profile.height = height;
    return await saveUserProfile(profile);
  }

  // 更新用户体重
  static Future<bool> updateUserWeight(double weight) async {
    UserProfile profile = getUserProfile();
    profile.weight = weight;
    return await saveUserProfile(profile);
  }

  // 更新用户头像路径
  static Future<bool> updateUserAvatar(String avatarPath) async {
    UserProfile profile = getUserProfile();
    profile.avatarPath = avatarPath;
    return await saveUserProfile(profile);
  }

  // 清除用户数据（调试用）
  static Future<void> clearUserData() async {
    await _prefs.remove(_userProfileKey);
    print('用户数据已清除');
  }

  // 6. ========== 工具函数 ==========
  
  // 清除所有数据（调试用）
  static Future<void> clearAllData() async {
    await _prefs.clear();
    print('所有数据已清除');
  }

  // 6. ========== 默认数据相关操作 ==========

  // 添加默认示例药品
  static Future<bool> addDefaultMedicines() async {
    List<Medicine> defaultMedicines = [
      Medicine(
        id: 'med_001',
        name: '阿司匹林',
        dose: '每次1片（100mg）',
        frequency: '每日1次',
        schedule: ['08:00'],
        notes: '建议饭后服用，避免空腹',
        createdAt: DateTime.now(),
        lastTaken: null,
      ),
      Medicine(
        id: 'med_002',
        name: '维生素D',
        dose: '每次2粒',
        frequency: '每日1次',
        schedule: ['09:00'],
        notes: '促进钙吸收，建议早晨服用',
        createdAt: DateTime.now(),
        lastTaken: null,
      ),
      Medicine(
        id: 'med_003',
        name: '降压药',
        dose: '每次1片',
        frequency: '每日2次',
        schedule: ['08:00', '20:00'],
        notes: '服药期间注意监测血压',
        createdAt: DateTime.now(),
        lastTaken: null,
      ),
    ];
    return await saveMedicines(defaultMedicines);
  }

  // 添加默认示例菜谱
  static Future<bool> addDefaultFoods() async {
    DateTime now = DateTime.now();

    // 今天的日期
    DateTime todayBreakfast = DateTime(now.year, now.month, now.day, 7, 30);
    DateTime todayLunch = DateTime(now.year, now.month, now.day, 12, 0);
    DateTime todayDinner = DateTime(now.year, now.month, now.day, 18, 30);

    List<FoodAnalysis> defaultFoods = [
      FoodAnalysis(
        id: 'food_001',
        foodName: '牛奶燕麦粥',
        imagePath: '',
        ingredients: ['牛奶', '燕麦', '鸡蛋'],
        calories: '约 350 大卡',
        protein: '12g',
        carbs: '45g',
        fat: '10g',
        suggestion: '营养均衡的早餐选择，燕麦富含膳食纤维，有助于消化',
        analyzedAt: todayBreakfast,
      ),
      FoodAnalysis(
        id: 'food_002',
        foodName: '西兰花炒鸡胸肉',
        imagePath: '',
        ingredients: ['鸡胸肉', '西兰花', '胡萝卜'],
        calories: '约 280 大卡',
        protein: '35g',
        carbs: '12g',
        fat: '8g',
        suggestion: '高蛋白低脂餐，适合健身人群，建议搭配主食',
        analyzedAt: todayLunch,
      ),
      FoodAnalysis(
        id: 'food_003',
        foodName: '清蒸鲈鱼',
        imagePath: '',
        ingredients: ['鲈鱼', '姜丝', '葱段'],
        calories: '约 220 大卡',
        protein: '25g',
        carbs: '2g',
        fat: '12g',
        suggestion: '清淡养胃，鱼肉富含优质蛋白和不饱和脂肪酸',
        analyzedAt: todayDinner,
      ),
    ];
    return await saveFoodAnalysis(defaultFoods);
  }

  // 初始化默认用户数据（首次使用时调用）
  static Future<void> initDefaultData() async {
    // 如果没有任何数据，则添加示例数据
    if (getMedicines().isEmpty) {
      print('检测到无药品数据，正在添加示例药品...');
      await addDefaultMedicines();
    }
    if (getFoodAnalysis().isEmpty) {
      print('检测到无菜谱数据，正在添加示例菜谱...');
      await addDefaultFoods();
    }
  }

  // 重置所有数据（清除并重新添加示例数据）
  static Future<void> resetAllData() async {
    await clearAllData();
    await addDefaultMedicines();
    await addDefaultFoods();
    print('数据已重置为默认示例数据');
  }
}