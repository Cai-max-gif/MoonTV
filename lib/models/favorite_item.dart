import '../constants/app_config.dart';

class FavoriteItem {
  final String id;
  final String source; // 来源标识
  final String title;
  final String sourceName;
  final String year;
  final String cover;
  final int totalEpisodes;
  final int saveTime;
  final String origin; // 添加origin字段

  FavoriteItem({
    required this.id,
    required this.source,
    required this.title,
    required this.sourceName,
    required this.year,
    required this.cover,
    required this.totalEpisodes,
    required this.saveTime,
    required this.origin,
  });

  factory FavoriteItem.fromJson(String key, Map<String, dynamic> json) {
    // 从key中分离source和id，格式为 "source+id"
    final parts = key.split(AppConfig.searchKeySeparator);
    final source = parts.length > 1 ? parts[0] : '';
    final id = parts.length > 1 ? parts[1] : key;
    
    return FavoriteItem(
      id: id,
      source: source,
      title: json[AppConfig.jsonTitle] ?? '',
      sourceName: json[AppConfig.jsonSourceName] ?? '',
      year: json[AppConfig.jsonYear] ?? '',
      cover: json[AppConfig.jsonCover] ?? '',
      totalEpisodes: json[AppConfig.jsonTotalEpisodes] ?? 0,
      saveTime: json[AppConfig.jsonSaveTime] ?? 0,
      origin: json[AppConfig.jsonOrigin] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonTitle: title,
      AppConfig.jsonSourceName: sourceName,
      AppConfig.jsonYear: year,
      AppConfig.jsonCover: cover,
      AppConfig.jsonTotalEpisodes: totalEpisodes,
      AppConfig.jsonSaveTime: saveTime,
      AppConfig.jsonOrigin: origin,
    };
  }
}
