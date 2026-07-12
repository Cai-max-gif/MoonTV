import 'play_record.dart';
import '../constants/app_config.dart';

/// 视频信息数据模型，用于VideoCard展示
class VideoInfo {
  final String id;
  final String source; // 来源标识
  final String title;
  final String sourceName;
  final String year;
  final String cover;
  final int index;
  final int totalEpisodes;
  final int playTime;
  final int totalTime;
  final int saveTime;
  final String searchTitle;
  final String? doubanId; // 豆瓣ID，用于豆瓣模式
  final int? bangumiId; // Bangumi ID，用于Bangumi模式
  final String? rate; // 评分，用于豆瓣模式
  final String? releaseDate; // 上映日期 (YYYY-MM-DD)，用于即将上映模式
  final String? releaseStatus; // 上映状态文本，如"3天后上映"、"今日上映"

  VideoInfo({
    required this.id,
    required this.source,
    required this.title,
    required this.sourceName,
    required this.year,
    required this.cover,
    required this.index,
    required this.totalEpisodes,
    required this.playTime,
    required this.totalTime,
    required this.saveTime,
    required this.searchTitle,
    this.doubanId,
    this.bangumiId,
    this.rate,
    this.releaseDate,
    this.releaseStatus,
  });

  /// 从PlayRecord创建VideoInfo
  factory VideoInfo.fromPlayRecord(PlayRecord playRecord, {
    String? doubanId,
    int? bangumiId,
    String? rate,
    String? releaseDate,
    String? releaseStatus,
  }) {
    return VideoInfo(
      id: playRecord.id,
      source: playRecord.source,
      title: playRecord.title,
      sourceName: playRecord.sourceName,
      year: playRecord.year,
      cover: playRecord.cover,
      index: playRecord.index,
      totalEpisodes: playRecord.totalEpisodes,
      playTime: playRecord.playTime,
      totalTime: playRecord.totalTime,
      saveTime: playRecord.saveTime,
      searchTitle: playRecord.searchTitle,
      doubanId: doubanId,
      bangumiId: bangumiId,
      rate: rate,
      releaseDate: releaseDate,
      releaseStatus: releaseStatus,
    );
  }

  /// 从JSON创建VideoInfo
  factory VideoInfo.fromJson(String key, Map<String, dynamic> json) {
    // 从key中分离source和id，格式为 "source+id"
    final parts = key.split(AppConfig.searchKeySeparator);
    final source = parts.length > 1 ? parts[0] : '';
    final id = parts.length > 1 ? parts[1] : key;

    return VideoInfo(
      id: id,
      source: source,
      title: json[AppConfig.jsonTitle] ?? '',
      sourceName: json[AppConfig.jsonSourceName] ?? '',
      year: json[AppConfig.jsonYear] ?? '',
      cover: json[AppConfig.jsonCover] ?? '',
      index: json[AppConfig.jsonIndex] ?? 0,
      totalEpisodes: json[AppConfig.jsonTotalEpisodes] ?? 0,
      playTime: json[AppConfig.jsonPlayTime] ?? 0,
      totalTime: json[AppConfig.jsonTotalTime] ?? 0,
      saveTime: json[AppConfig.jsonSaveTime] ?? 0,
      searchTitle: json[AppConfig.jsonSearchTitle] ?? '',
      doubanId: json[AppConfig.jsonDoubanId],
      bangumiId: json[AppConfig.jsonBangumiId],
      rate: json[AppConfig.jsonRate],
      releaseDate: json[AppConfig.jsonReleaseDate],
      releaseStatus: json[AppConfig.jsonReleaseStatus],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonTitle: title,
      AppConfig.jsonSourceName: sourceName,
      AppConfig.jsonYear: year,
      AppConfig.jsonCover: cover,
      AppConfig.jsonIndex: index,
      AppConfig.jsonTotalEpisodes: totalEpisodes,
      AppConfig.jsonPlayTime: playTime,
      AppConfig.jsonTotalTime: totalTime,
      AppConfig.jsonSaveTime: saveTime,
      AppConfig.jsonSearchTitle: searchTitle,
      AppConfig.jsonDoubanId: doubanId,
      AppConfig.jsonBangumiId: bangumiId,
      AppConfig.jsonRate: rate,
      AppConfig.jsonReleaseDate: releaseDate,
      AppConfig.jsonReleaseStatus: releaseStatus,
    };
  }

  /// 获取播放进度百分比
  double get progressPercentage {
    if (totalTime <= 0) return 0.0;
    return (playTime / totalTime).clamp(0.0, 1.0);
  }

  /// 格式化播放时间
  String get formattedPlayTime {
    final hours = playTime ~/ AppConfig.secondsPerHour;
    final minutes = (playTime % AppConfig.secondsPerHour) ~/ AppConfig.secondsPerMinute;
    final seconds = playTime % AppConfig.secondsPerMinute;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  static String formatTotalTime(int totalTime) {
    final hours = totalTime ~/ AppConfig.secondsPerHour;
    final minutes = (totalTime % AppConfig.secondsPerHour) ~/ AppConfig.secondsPerMinute;
    final seconds = totalTime % AppConfig.secondsPerMinute;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
