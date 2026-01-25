import 'package:flutter/material.dart';
import 'scan_medicine.dart';
import 'scan_menu.dart';
import 'chat_page.dart';
import '../services/home_functions.dart'; // [!code ++] 导入框架函数文件

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康AI管家'),
        backgroundColor: Colors.blue,
      ),
      body: Row(
        children: [
          // ==================== 左侧功能导航栏 ====================
          // [!code ++] 宽度调整为120，更紧凑
          _buildSidebar(),
          
          // ==================== 右侧健康概览内容 ====================
          _buildMainContent(),
        ],
      ),
    );
  }

  // ==================== 左侧功能导航栏 ====================
  Widget _buildSidebar() {
    return Container(
      width: 120, 
      color: Colors.grey[50],
      child: Column(
        children: [
          const SizedBox(height: 15), 
          
          // ==================== 功能按钮1：药品识别 ====================
          // [!code ++] 跳转到药品扫描页面
          _buildSidebarButton(
            icon: Icons.medical_services,
            label: '药品识别',
            color: Colors.green,
            page: const ScanMedicinePage(),
          ),
          const SizedBox(height: 10), 
          
          // ==================== 功能按钮2：菜谱分析 ====================
          // [!code ++] 跳转到菜谱分析页面
          _buildSidebarButton(
            icon: Icons.restaurant,
            label: '菜谱分析',
            color: Colors.orange,
            page: const ScanMenuPage(),
          ),
          const SizedBox(height: 10), 
          
          // ==================== 功能按钮3：健康咨询 ====================
          // [!code ++] 跳转到健康聊天页面
          _buildSidebarButton(
            icon: Icons.chat,
            label: '健康咨询',
            color: Colors.blue,
            page: const ChatPage(),
          ),
          
          const Spacer(),
          
          // ==================== 用户信息区域 ====================
          // [!code ++] 显示用户头像和名称
          _buildUserInfo(),
        ],
      ),
    );
  }

  // ==================== 侧边栏按钮组件 ====================
  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required Color color,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8), 
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), 
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), 
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 22), 
            const SizedBox(width: 8), 
            Text(
              label,
              style: const TextStyle(fontSize: 14), 
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 用户信息区域 ====================
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12), 
      child: const Column(
        children: [
          CircleAvatar(
            radius: 25, 
            child: Icon(Icons.person, size: 25), 
          ),
          SizedBox(height: 8), 
          Text(
            '用户',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 
          ),
        ],
      ),
    );
  }

  // ==================== 右侧主内容区域 ====================
  Widget _buildMainContent() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16), 
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== 页面主标题 ====================
              const Text(
                '今日健康概览',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), 
              ),
              const SizedBox(height: 16), 
              
              // ==================== 模块1：合并健康数据卡片 ====================
              // [!code ++] 功能：合并显示卡路里摄入和需服药物（无图标）
              // [!code ++] 开发任务：需要实现 home_functions.dart 中的：
              // [!code ++]  1. getTodayCalories() - 获取卡路里数据
              // [!code ++]  2. getTodayMedicines() - 获取药品数据
              _buildCombinedDataCard(),
              const SizedBox(height: 12), 
              
              // ==================== 模块2：健康时间线卡片 ====================
              // [!code ++] 功能：根据当前时间给出个性化健康建议（无标题）
              // [!code ++] 开发任务：需要实现 home_functions.dart 中的 getHealthTimeline() 函数
              // [!code ++] 特别说明：需要调用DeepSeek API生成自然语言建议
              _buildTimelineCard(),
              const SizedBox(height: 12), 
              
              // ==================== 模块3：健康关联分析卡片 ====================
              // [!code ++] 功能：分析药品与食物的相互作用
              // [!code ++] 开发任务：需要实现 home_functions.dart 中的 getInteractionAnalysis() 函数
              _buildAnalysisCard(),
              const SizedBox(height: 12), 
              
              // ==================== 模块4：健康分数卡片 ====================
              // [!code ++] 功能：显示今日健康分数（初始90分）
              // [!code ++] 开发任务：需要实现 home_functions.dart 中的 getHealthScore() 函数
              _buildScoreCard(),
              const SizedBox(height: 12), 
              
              // ==================== 模块5：下次服药提醒卡片 ====================
              // [!code ++] 功能：显示下一次服药的时间和药品
              // [!code ++] 开发任务：需要实现 home_functions.dart 中的 getNextMedicine() 函数
              _buildReminderCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 模块1：合并健康数据卡片 ====================
  // [!code ++] 新组件：同时显示卡路里和药物信息，无图标
  Widget _buildCombinedDataCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            // 第一行：卡路里数据
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：标签
                const SizedBox(
                  width: 120, // 固定宽度，对齐美观
                  child: Text(
                    '卡路里摄入：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // 右侧：数据
                Expanded(
                  child: Text(
                    HomeFunctions.getTodayCalories(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第二行：药品数据
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：标签
                const SizedBox(
                  width: 120,
                  child: Text(
                    '需服药物：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // 右侧：数据
                Expanded(
                  child: Text(
                    HomeFunctions.getTodayMedicines(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 模块2：健康时间线卡片 ====================
  Widget _buildTimelineCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            // 显示建议
            Text(
              HomeFunctions.getHealthTimeline(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5, // 行高增加，更易阅读
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 模块3：健康关联分析卡片 ====================
  Widget _buildAnalysisCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            const Text(
              '🔬 健康关联分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 分析内容
            FutureBuilder<String>(
              future: HomeFunctions.getInteractionAnalysis(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                       SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                       SizedBox(width: 10),
                       Text("正在进行AI关联分析...", style: TextStyle(color: Colors.grey)),
                    ],
                  );
                }
                return Text(
                  snapshot.data ?? "暂无分析",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 模块4：健康分数卡片 ====================
  Widget _buildScoreCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            const Text(
              '⭐ 今日健康分数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 分数内容
            Text(
              HomeFunctions.getHealthScore(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 模块5：下次服药提醒卡片 ====================
  Widget _buildReminderCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            const Text(
              '💊 下次服药提醒',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 提醒内容
            Text(
              HomeFunctions.getNextMedicine(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}