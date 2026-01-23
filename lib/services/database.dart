import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // 用于JSON转换
import '../models/medicine.dart';
import '../models/food.dart';
class DatabaseService {
  // 存储键名常量
  static const String _medicinesKey = 'medicines';
  static const String _foodAnalysisKey = 'food_analysis';
  
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

  // 4. ========== 工具函数 ==========
  
  // 清除所有数据（调试用）
  static Future<void> clearAllData() async {
    await _prefs.clear();
    print('所有数据已清除');
  }
}