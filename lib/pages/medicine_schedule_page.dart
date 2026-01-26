import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database.dart';
import '../models/medicine.dart';

class MedicineSchedulePage extends StatefulWidget {
  const MedicineSchedulePage({super.key});

  @override
  State<MedicineSchedulePage> createState() => _MedicineSchedulePageState();
}

class _MedicineSchedulePageState extends State<MedicineSchedulePage> {
  List<Medicine> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    await DatabaseService.init();
    setState(() {
      _isLoading = true;
    });

    try {
      _medicines = DatabaseService.getMedicines();
    } catch (e) {
      debugPrint('加载服药计划失败: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 获取当前时间
  DateTime get _now => DateTime.now();

  // 获取下一个服药时间
  Map<String, dynamic>? _getNextMedicine() {
    if (_medicines.isEmpty) return null;

    List<Map<String, dynamic>> allSchedules = [];

    for (var med in _medicines) {
      for (var timeStr in med.schedule) {
        try {
          List<String> parts = timeStr.trim().split(":");
          if (parts.length < 2) continue;
          int h = int.parse(parts[0]);
          int m = int.parse(parts[1]);

          DateTime scheduleTime = DateTime(_now.year, _now.month, _now.day, h, m);

          // 如果时间已过，算明天的
          if (scheduleTime.isBefore(_now)) {
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

    if (allSchedules.isEmpty) return null;

    allSchedules.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return allSchedules.first;
  }

  // 获取今日服药时间表
  List<Map<String, dynamic>> _getTodaySchedule() {
    if (_medicines.isEmpty) return [];

    List<Map<String, dynamic>> todaySchedule = [];

    for (var med in _medicines) {
      for (var timeStr in med.schedule) {
        try {
          List<String> parts = timeStr.trim().split(":");
          if (parts.length < 2) continue;
          int h = int.parse(parts[0]);
          int m = int.parse(parts[1]);

          DateTime scheduleTime = DateTime(_now.year, _now.month, _now.day, h, m);

          todaySchedule.add({
            "time": scheduleTime,
            "medicine": med,
            "taken": _now.isAfter(scheduleTime.add(const Duration(minutes: 30))),
          });
        } catch (e) {
          continue;
        }
      }
    }

    todaySchedule.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return todaySchedule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服药计划'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无服药计划',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮添加药品',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加药品'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
            // 下次服药提醒卡片
            _buildNextReminderCard(),
            const SizedBox(height: 16),

            // 药品列表
            _buildMedicineList(),
            const SizedBox(height: 16),

            // 今日时间表
            _buildTodayScheduleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextReminderCard() {
    final next = _getNextMedicine();

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  '下次服药提醒',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (next != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      DateFormat('HH:mm').format(next['time'] as DateTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (next['medicine'] as Medicine).name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '剂量: ${(next['medicine'] as Medicine).dose}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (next['time'] as DateTime).day != _now.day ? '明天' : '今天',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ] else ...[
              const Text(
                '今日服药已完成',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineList() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '我的药品 (${_medicines.length}种)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._medicines.map((med) => _buildMedicineCard(med)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  med.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              _buildInfoChip(Icons.qr_code, '剂量: ${med.dose}'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.repeat, med.frequency),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: med.schedule
                .map((time) => Chip(
                      label: Text(time),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[800]),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTodayScheduleCard() {
    final todaySchedule = _getTodaySchedule();

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '今日服药时间表',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (todaySchedule.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '今日暂无服药安排',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: todaySchedule.map((item) => _buildScheduleItem(item)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    final time = item['time'] as DateTime;
    final med = item['medicine'] as Medicine;
    final taken = item['taken'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taken ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: taken ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 时间
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: taken ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateFormat('HH:mm').format(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 药品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '剂量: ${med.dose}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: taken ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              taken ? '已服用' : '待服用',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
