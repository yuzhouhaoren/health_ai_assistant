import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/database.dart'; // 导入数据库服务获取健康数据

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ==================== 状态管理 ====================
  final List<Map<String, dynamic>> _messages = []; // 聊天记录
  final TextEditingController _textController = TextEditingController(); // 输入框控制器
  bool _isLoading = false; // 是否正在加载AI回复
  final ScrollController _scrollController = ScrollController(); // 滚动控制器

  // ==================== DeepSeek API 配置 ====================
  static const String _apiKey = 'sk-a00b6f5bd699411f89701a26dced57d4'; // 你的API密钥
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions'; // DeepSeek API地址

  @override
  void initState() {
    super.initState();
    // 添加AI欢迎消息
    _addSystemMessage();
  }

  // ==================== 核心功能：发送消息 ====================
  Future<void> _sendMessage() async {
    // 1. 验证输入
    String text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 2. 清空输入框并添加用户消息
    _textController.clear();
    _addMessage(text, true);

    // 3. 显示加载状态
    setState(() => _isLoading = true);

    try {
      // 4. 获取AI回复
      String aiResponse = await _getAIResponse(text);
      _addMessage(aiResponse, false);
    } catch (e) {
      // 5. 错误处理
      print('API调用错误: $e');
      _addMessage('抱歉，我暂时无法回答。请检查网络或稍后再试。', false);
    } finally {
      // 6. 恢复状态
      setState(() => _isLoading = false);
    }
  }

  // ==================== AI回复获取（核心逻辑） ====================
  Future<String> _getAIResponse(String userMessage) async {
    // 1. 获取用户健康数据
    final medicines = DatabaseService.getMedicines();
    final foods = DatabaseService.getFoodAnalysis();

    // 2. 构建智能提示词（让AI了解用户情况）
    String healthContext = _buildHealthContext(medicines, foods);
    
    // 3. 构造完整的对话消息
    final messages = [
      {
        "role": "system",
        "content": '''你是一位专业、友好的AI健康顾问。请遵循以下原则：
        1. 结合用户的健康数据提供个性化建议
        2. 用口语化的中文回答，简洁明了
        3. 涉及医疗问题时应建议咨询医生
        4. 保持积极和鼓励的态度
        
        用户健康数据：
        $healthContext'''
      },
      {"role": "user", "content": userMessage}
    ];

    // 4. 准备API请求
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "model": "deepseek-chat",
      "messages": messages,
      "temperature": 0.7,
      "max_tokens": 1000,
    });

    // 5. 发送HTTP请求
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: headers,
      body: body,
    );

    // 6. 处理响应
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('API请求失败: ${response.statusCode}');
    }
  }

  // ==================== 构建健康数据上下文 ====================
  String _buildHealthContext(List medicines, List foods) {
    StringBuffer context = StringBuffer();
    
    // 药品信息
    if (medicines.isNotEmpty) {
      context.writeln('【今日用药】');
      for (var med in medicines.take(3)) { // 只显示最近3种药
        context.writeln('- ${med.name}: ${med.dose}，${med.frequency}');
      }
      if (medicines.length > 3) {
        context.writeln('...等共${medicines.length}种药品');
      }
      context.writeln();
    } else {
      context.writeln('【今日用药】无记录\n');
    }
    
    // 饮食信息
    if (foods.isNotEmpty) {
      context.writeln('【今日饮食】');
      for (var food in foods.take(3)) { // 只显示最近3条记录
        context.writeln('- ${food.foodName}: ${food.calories}');
      }
      if (foods.length > 3) {
        context.writeln('...等共${foods.length}条饮食记录');
      }
    } else {
      context.writeln('【今日饮食】无记录');
    }
    
    return context.toString();
  }

  // ==================== 消息管理 ====================
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'time': DateTime.now(),
      });
    });
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addSystemMessage() {
    _addMessage(
      '👋 你好！我是你的AI健康助手。我已经了解你今日的用药和饮食情况，可以为你提供个性化的健康建议。',
      false,
    );
  }

  // ==================== UI构建 ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 健康咨询'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 聊天消息区域
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.health_and_safety, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('开始你的健康咨询',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              children: [
                // 输入框
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入健康问题...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),

                // 发送按钮
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 聊天气泡组件 ====================
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像（左侧）
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.health_and_safety, size: 18, color: Colors.white),
              ),
            ),
          
          // 消息内容
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 气泡
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.blue[900] : Colors.grey[900],
                    ),
                  ),
                ),
                
                // 时间戳
                const SizedBox(height: 4),
                Text(
                  _formatTime(message['time']),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // 用户头像（右侧）
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== 辅助函数 ====================
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 清理资源
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}