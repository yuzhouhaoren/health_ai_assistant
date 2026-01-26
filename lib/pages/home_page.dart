import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'scan_medicine.dart';
import 'scan_menu.dart';
import 'chat_page.dart';
import 'today_menu_page.dart';
import 'medicine_schedule_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/home_functions.dart';
import '../services/database.dart';
import '../services/news_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 用户数据控制器
  late UserProfile _userProfile;
  final GlobalKey<_HomePageState> _homeKey = GlobalKey<_HomePageState>();

  // 是否为移动端（屏幕宽度小于600）
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 加载用户数据
  Future<void> _loadUserData() async {
    await DatabaseService.init();
    setState(() {
      _userProfile = DatabaseService.getUserProfile();
    });
  }

  // 刷新用户数据（用于编辑后更新界面）
  void _refreshUserData() {
    setState(() {
      _userProfile = DatabaseService.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康AI管家'),
        backgroundColor: Colors.blue,
        // 移动端显示菜单按钮
        leading: _isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
      ),
      // 移动端使用Drawer，桌面端使用内联侧边栏
      drawer: _isMobile ? _buildMobileDrawer() : null,
      body: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  // ==================== 移动端布局（竖向） ====================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎语
            Text(
              '欢迎，${_userProfile.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'BMI: ${_userProfile.bmi.toStringAsFixed(1)} (${_userProfile.bmiStatus})',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // 模块1：合并健康数据卡片
            _buildCombinedDataCard(),
            const SizedBox(height: 12),

            // 模块2：健康时间线卡片
            _buildTimelineCard(),
            const SizedBox(height: 12),

            // 模块3：健康关联分析卡片
            _buildAnalysisCard(),
            const SizedBox(height: 12),

            // 模块4：健康分数卡片
            _buildScoreCard(),
            const SizedBox(height: 12),

            // 模块5：下次服药提醒卡片
            _buildReminderCard(),
            const SizedBox(height: 12),

            // 模块6：健康新闻卡片
            _buildNewsCard(),
          ],
        ),
      ),
    );
  }

  // ==================== 桌面端布局（横向 Row） ====================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左侧功能导航栏
        _buildSidebar(),

        // 右侧健康概览内容
        _buildMainContent(),
      ],
    );
  }

  // ==================== 移动端Drawer菜单 ====================
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 40),
          // 移动端用户信息（Drawer顶部）
          _buildDrawerUserInfo(),
          const Divider(),

          // 功能按钮列表
          _buildDrawerButton(
            icon: Icons.medical_services,
            label: '药品识别',
            color: Colors.green,
            page: const ScanMedicinePage(),
          ),
          _buildDrawerButton(
            icon: Icons.restaurant,
            label: '菜谱分析',
            color: Colors.orange,
            page: const ScanMenuPage(),
          ),
          _buildDrawerButton(
            icon: Icons.chat,
            label: '健康咨询',
            color: Colors.blue,
            page: const ChatPage(),
          ),
          _buildDrawerButton(
            icon: Icons.today,
            label: '今日菜谱',
            color: Colors.purple,
            page: const TodayMenuPage(),
          ),
          _buildDrawerButton(
            icon: Icons.medication,
            label: '服药计划',
            color: Colors.red,
            page: const MedicineSchedulePage(),
          ),

          const Spacer(),

          // 编辑信息按钮
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.grey),
            title: const Text('编辑个人信息'),
            onTap: () {
              Navigator.pop(context);
              _showUserEditDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Drawer中的用户信息
  Widget _buildDrawerUserInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BMI: ${_userProfile.bmi.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drawer按钮组件
  Widget _buildDrawerButton({
    required IconData icon,
    required String label,
    required Color color,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }

  // ==================== 左侧功能导航栏（桌面端） ====================
  Widget _buildSidebar() {
    return Container(
      width: 130,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 15),

          // 功能按钮1：药品识别
          _buildSidebarButton(
            icon: Icons.medical_services,
            label: '药品识别',
            color: Colors.green,
            page: const ScanMedicinePage(),
          ),
          const SizedBox(height: 8),

          // 功能按钮2：菜谱分析
          _buildSidebarButton(
            icon: Icons.restaurant,
            label: '菜谱分析',
            color: Colors.orange,
            page: const ScanMenuPage(),
          ),
          const SizedBox(height: 8),

          // 功能按钮3：健康咨询
          _buildSidebarButton(
            icon: Icons.chat,
            label: '健康咨询',
            color: Colors.blue,
            page: const ChatPage(),
          ),
          const SizedBox(height: 8),

          // 新功能按钮4：今日菜谱
          _buildSidebarButton(
            icon: Icons.today,
            label: '今日菜谱',
            color: Colors.purple,
            page: const TodayMenuPage(),
          ),
          const SizedBox(height: 8),

          // 新功能按钮5：服药计划
          _buildSidebarButton(
            icon: Icons.medication,
            label: '服药计划',
            color: Colors.red,
            page: const MedicineSchedulePage(),
          ),

          const Spacer(),

          // 用户信息区域
          _buildUserInfo(),
        ],
      ),
    );
  }

  // 侧边栏按钮组件
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
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 用户信息区域
  Widget _buildUserInfo() {
    return GestureDetector(
      onTap: () => _showUserEditDialog(),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 8),
            Text(
              _userProfile.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'BMI: ${_userProfile.bmi.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.edit,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // 构建用户头像
  Widget _buildAvatar() {
    if (kIsWeb) {
      return _buildDefaultAvatar();
    }

    if (_userProfile.avatarPath.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: FileImage(File(_userProfile.avatarPath)),
        child: const Icon(Icons.person, size: 35),
      );
    } else if (_userProfile.avatarUrl != null &&
        _userProfile.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(_userProfile.avatarUrl!),
        child: const Icon(Icons.person, size: 35),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.blue[100],
      child: const Icon(Icons.person, size: 35, color: Colors.blue),
    );
  }

  // 显示用户信息编辑对话框
  void _showUserEditDialog() {
    final nameController = TextEditingController(text: _userProfile.name);
    final ageController =
        TextEditingController(text: _userProfile.age.toString());
    final heightController =
        TextEditingController(text: _userProfile.height.toStringAsFixed(1));
    final weightController =
        TextEditingController(text: _userProfile.weight.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑个人信息'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatarEditArea(),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: '年龄',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: '身高 (cm)',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: '体重 (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'BMI: ${_userProfile.bmi.toStringAsFixed(1)} (${_userProfile.bmiStatus})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                int age = int.tryParse(ageController.text.trim()) ?? 25;
                double height =
                    double.tryParse(heightController.text.trim()) ?? 170.0;
                double weight =
                    double.tryParse(weightController.text.trim()) ?? 65.0;

                _userProfile.name = name.isNotEmpty ? name : '用户';
                _userProfile.age = age.clamp(1, 120);
                _userProfile.height = height.clamp(50, 250);
                _userProfile.weight = weight.clamp(20, 300);

                await DatabaseService.saveUserProfile(_userProfile);
                _refreshUserData();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存成功！')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarEditArea() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAvatarSourceDialog(),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: ClipOval(
              child: kIsWeb
                  ? const Icon(Icons.person, size: 40, color: Colors.blue)
                  : (_userProfile.avatarPath.isNotEmpty
                      ? Image.file(
                          File(_userProfile.avatarPath),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40);
                          },
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.blue)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb ? 'Web端暂不支持本地图片' : '点击更换头像',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showAvatarSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择头像来源'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _pickAvatarFromGallery();
              },
              child: const Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('从相册选择'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _takeAvatarPhoto();
              },
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('拍照'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.close, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('取消'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _userProfile.avatarPath = pickedFile.path;
        });
        await DatabaseService.updateUserAvatar(_userProfile.avatarPath);
        _refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更换成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择头像失败：$e')),
      );
    }
  }

  Future<void> _takeAvatarPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _userProfile.avatarPath = pickedFile.path;
        });
        await DatabaseService.updateUserAvatar(_userProfile.avatarPath);
        _refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更换成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失败：$e')),
      );
    }
  }

  // ==================== 右侧主内容区域（桌面端） ====================
  Widget _buildMainContent() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日健康概览',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildCombinedDataCard(),
              const SizedBox(height: 12),

              _buildTimelineCard(),
              const SizedBox(height: 12),

              _buildAnalysisCard(),
              const SizedBox(height: 12),

              _buildScoreCard(),
              const SizedBox(height: 12),

              _buildReminderCard(),
              const SizedBox(height: 12),

              _buildNewsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 模块1：合并健康数据卡片 ====================
  Widget _buildCombinedDataCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    '卡路里摄入：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    HomeFunctions.getTodayCalories(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    '需服药物：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
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
            FutureBuilder<String>(
              future: HomeFunctions.getHealthTimeline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text("正在生成健康建议...", style: TextStyle(color: Colors.grey)),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    "获取健康建议失败：${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  );
                } else {
                  return Text(
                    snapshot.data ?? "暂无建议",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 模块3：健康关联分析卡片（无emoji） ====================
  Widget _buildAnalysisCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '健康关联分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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

  // ==================== 模块4：健康分数卡片（无emoji） ====================
  Widget _buildScoreCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日健康分数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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

  // ==================== 模块5：下次服药提醒卡片（无emoji） ====================
  Widget _buildReminderCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '下次服药提醒',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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

  // ==================== 模块6：健康新闻卡片（无emoji） ====================
  Widget _buildNewsCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.newspaper, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '今日健康资讯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('换一批'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<HealthNews>>(
              future: HomeFunctions.getHealthNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('加载失败，请稍后重试'),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final newsList = snapshot.data!;
                  return Column(
                    children: newsList.map((news) => _buildNewsItem(news)).toList(),
                  );
                } else {
                  return const Center(
                    child: Text('暂无健康资讯'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(HealthNews news) {
    return InkWell(
      onTap: () {
        if (news.url.isNotEmpty) {
          _launchUrl(news.url);
        }
      },
      child: Container(
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
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              news.summary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.source,
                  size: 12,
                  color: Colors.blue[400],
                ),
                const SizedBox(width: 4),
                Text(
                  news.source,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[400],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  NewsService.formatPublishTime(news.publishTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('点击了新闻链接')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接：$e')),
        );
      }
    }
  }
}
