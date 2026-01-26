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
}