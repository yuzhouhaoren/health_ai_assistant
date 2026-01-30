// 健康新闻服务
import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthNews {
  final String title;
  final String summary;
  final String source;
  final String url;
  final String imageUrl;
  final DateTime publishTime;

  HealthNews({
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishTime,
  });

  factory HealthNews.fromJson(Map<String, dynamic> json) {
    return HealthNews(
      title: json['title'] ?? '健康资讯',
      summary: json['summary'] ?? '',
      source: json['source'] ?? '健康日报',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishTime: json['publishTime'] != null
          ? DateTime.parse(json['publishTime'])
          : DateTime.now(),
    );
  }
}

class NewsService {
  // 使用免费的新闻API
  static const String _newsApiKey = 'your_newsapi_key'; // 需要替换为真实的API key
  static const String _newsUrl = 'https://newsapi.org/v2/top-headlines';

  // 预置的健康新闻（当API不可用时使用）
  static List<Map<String, dynamic>> getPresetNews() {
    return [
      {
        'title': '研究发现：每天快走30分钟可显著降低心血管疾病风险',
        'summary': '最新研究表明，规律的有氧运动可以有效预防心脏病和中风，建议每天保持30分钟以上的中等强度运动。',
        'source': '健康时报',
        'url': 'https://www.jkb.com.cn/',
        'imageUrl': '',
        'publishTime': DateTime.now().toIso8601String(),
      },
      {
        'title': '营养专家推荐：春季养生多吃这5种食物',
        'summary': '春季是养生的好时节，专家建议多吃韭菜、香椿、荠菜等时令蔬菜，有助于调理身体、增强免疫力。',
        'source': '人民网健康',
        'url': 'https://health.people.com.cn/',
        'imageUrl': '',
        'publishTime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'title': '睡眠质量与寿命的关系：科学家揭示重要发现',
        'summary': '研究表明，每晚保持7-8小时的优质睡眠有助于延长寿命，长期睡眠不足可能增加多种慢性疾病风险。',
        'source': '生命时报',
        'url': 'https://www.lifetimes.cn/',
        'imageUrl': '',
        'publishTime': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'title': '科学补水：运动后喝水的最佳时机和方式',
        'summary': '运动后不宜立即大量饮水，专家建议少量多次，每隔15-20分钟补充150-200毫升水为最佳。',
        'source': '体坛周报',
        'url': 'https://www.sportsdaily.com.cn/',
        'imageUrl': '',
        'publishTime': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'title': '心理健康新观点：社交活动对延缓认知衰老至关重要',
        'summary': '最新研究显示，保持积极的社交生活可以延缓大脑认知功能衰退，建议老年人多参与社区活动。',
        'source': '科技日报',
        'url': 'http://www.stdaily.com/',
        'imageUrl': '',
        'publishTime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  // 获取健康新闻
  static Future<List<HealthNews>> getHealthNews() async {
    try {
      // 尝试使用NewsAPI（需要替换为真实的API key）
      final response = await http.get(
        Uri.parse('$_newsUrl?category=health&country=cn&pageSize=10'),
        headers: {
          'Authorization': 'Bearer $_newsApiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          List<dynamic> articles = data['articles'];
          return articles.take(2).map((article) => HealthNews(
            title: article['title'] ?? '健康资讯',
            summary: article['description'] ?? '',
            source: article['source']['name'] ?? '健康日报',
            url: article['url'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            publishTime: article['publishedAt'] != null
                ? DateTime.parse(article['publishedAt'])
                : DateTime.now(),
          )).toList();
        }
      }
    } catch (e) {
      print('获取新闻API失败: $e');
    }

    // 如果API不可用，返回预设新闻（随机选择2条）
    final presetNews = getPresetNews();
    final random = DateTime.now().day % presetNews.length;
    final selectedNews = [
      presetNews[random],
      presetNews[(random + 1) % presetNews.length],
    ];

    return selectedNews.map((news) => HealthNews.fromJson(news)).toList();
  }

  // 获取格式化的时间文本
  static String formatPublishTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
