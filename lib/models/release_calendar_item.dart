import '../constants/app_config.dart';
import '../constants/app_strings.dart';

/// 即将上映数据模型
class ReleaseCalendarItem {
  final String id;
  final String title;
  final String type;
  final String director; // 导演
  final String actors; // 主演
  final String region; // 地区
  final String genre; // 类型/标签
  final String releaseDate; // 发布日期 (YYYY-MM-DD)
  final String? cover; // 封面图片URL
  final String? description; // 简介
  final int? episodes; // 集数（电视剧）
  final String source; // 数据来源
  final int createdAt; // 记录创建时间戳
  final int updatedAt; // 记录更新时间戳

  ReleaseCalendarItem({
    required this.id,
    required this.title,
    required this.type,
    required this.director,
    required this.actors,
    required this.region,
    required this.genre,
    required this.releaseDate,
    this.cover,
    this.description,
    this.episodes,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReleaseCalendarItem.fromJson(Map<String, dynamic> json) {
    return ReleaseCalendarItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      director: json['director'] as String? ?? '',
      actors: json['actors'] as String? ?? '',
      region: json['region'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      cover: json['cover'] as String?,
      description: json['description'] as String?,
      episodes: json['episodes'] as int?,
      source: json['source'] as String? ?? AppConfig.sourceIdManmankan,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'director': director,
      'actors': actors,
      'region': region,
      'genre': genre,
      'releaseDate': releaseDate,
      'cover': cover,
      'description': description,
      'episodes': episodes,
      'source': source,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 计算距离上映还有几天
  /// 返回正数表示还有几天上映，负数表示已上映几天，0表示今天上映
  int getDaysUntilRelease() {
    if (releaseDate.isEmpty) return 0;

    try {
      final release = DateTime.parse(releaseDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final releaseDay = DateTime(release.year, release.month, release.day);

      return releaseDay.difference(today).inDays;
    } catch (e) {
      // 日期格式错误时返回0
      return 0;
    }
  }

  /// 获取上映状态文本
  String getReleaseStatusText() {
    final days = getDaysUntilRelease();
    if (days < 0) {
      return '${AppStrings.releaseAlready}${-days}天';
    } else if (days == 0) {
      return AppStrings.releaseToday;
    } else {
      return '$days${AppStrings.releaseDaysLater}';
    }
  }

  /// 获取年份
  String get year {
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      return releaseDate.substring(0, 4);
    }
    return '';
  }
}
