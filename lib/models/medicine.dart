// 药品模型 - 存储药品信息
class Medicine {
  String id;           // 药品唯一ID
  String name;         // 药品名称
  String dose;         // 服用剂量，如"每次1片"
  String frequency;    // 服用频率，如"每日3次"
  List<String> schedule; // 具体服药时间，如 ["08:00", "12:00", "20:00"]
  String? notes;       // 注意事项
  DateTime createdAt;  // 创建时间
  DateTime? lastTaken; // 上次服药时间

  // 构造函数
  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.schedule,
    this.notes,
    required this.createdAt,
    this.lastTaken,
  });

  // 从JSON创建对象（从API获取数据时使用）
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '未知药品',
      dose: json['dose'] ?? '每次1片',
      frequency: json['frequency'] ?? '每日1次',
      schedule: (json['schedule'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastTaken: json['lastTaken'] != null ? DateTime.parse(json['lastTaken']) : null,
    );
  }

  // 转换为JSON（存储到数据库时使用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'frequency': frequency,
      'schedule': schedule,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastTaken': lastTaken?.toIso8601String(),
    };
  }

  // 获取下一次服药时间（简单逻辑）
  String getNextTime() {
    if (schedule.isEmpty) return '无定时';
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (var time in schedule) {
      if (time.compareTo(currentTime) > 0) {
        return time;
      }
    }
    return schedule[0]; // 如果今天都已过时，返回明天的第一次
  }

  // 检查现在是否需要服药
  bool shouldTakeNow() {
    if (schedule.isEmpty) return false;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // 简单逻辑：当前时间与服药时间相差10分钟内
    for (var time in schedule) {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      final difference = now.difference(scheduledTime).inMinutes.abs();
      if (difference <= 10) {
        return true;
      }
    }
    return false;
  }
}