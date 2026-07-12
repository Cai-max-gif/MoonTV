import '../constants/app_config.dart';

/// 播放记录数据模型
class PlayRecord {
  final String id;
  final String source;
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

  PlayRecord({
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
  });

  /// 从JSON创建PlayRecord
  factory PlayRecord.fromJson(String key, Map<String, dynamic> json) {
    // 从key中分离source和id，格式为 "source+id"
    final parts = key.split(AppConfig.searchKeySeparator);
    final source = parts.length > 1 ? parts[0] : '';
    final id = parts.length > 1 ? parts[1] : key;
    
    return PlayRecord(
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

  /// 格式化总时间
  String get formattedTotalTime {
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
