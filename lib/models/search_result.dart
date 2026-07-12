import 'video_info.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

/// 搜索结果数据模型
class SearchResult {
  final String id;
  final String title;
  final String poster;
  final List<String> episodes;
  final List<String> episodesTitles;
  final String source;
  final String sourceName;
  final String? class_;
  final String year;
  final String? desc;
  final String? typeName;
  final int? doubanId;

  SearchResult({
    required this.id,
    required this.title,
    required this.poster,
    required this.episodes,
    required this.episodesTitles,
    required this.source,
    required this.sourceName,
    this.class_,
    required this.year,
    this.desc,
    this.typeName,
    this.doubanId,
  });

  /// 从JSON创建SearchResult
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json[AppConfig.jsonId] ?? '',
      title: json[AppConfig.jsonTitle] ?? '',
      poster: json[AppConfig.jsonPoster] ?? '',
      episodes: json[AppConfig.jsonEpisodes] != null 
          ? List<String>.from(json[AppConfig.jsonEpisodes])
          : [],
      episodesTitles: json[AppConfig.jsonEpisodesTitles] != null 
          ? List<String>.from(json[AppConfig.jsonEpisodesTitles])
          : [],
      source: json[AppConfig.jsonSource] ?? '',
      sourceName: json[AppConfig.jsonSourceName] ?? '',
      class_: json[AppConfig.jsonClass],
      year: json[AppConfig.jsonYear] ?? '',
      desc: json[AppConfig.jsonDesc],
      typeName: json[AppConfig.jsonTypeName],
      doubanId: json[AppConfig.jsonDoubanId],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonPoster: poster,
      AppConfig.jsonEpisodes: episodes,
      AppConfig.jsonEpisodesTitles: episodesTitles,
      AppConfig.jsonSource: source,
      AppConfig.jsonSourceName: sourceName,
      AppConfig.jsonClass: class_,
      AppConfig.jsonYear: year,
      AppConfig.jsonDesc: desc,
      AppConfig.jsonTypeName: typeName,
      AppConfig.jsonDoubanId: doubanId,
    };
  }

  /// 获取显示用的类型名称
  String get displayType {
    return typeName ?? class_ ?? AppStrings.unknown;
  }

  /// 获取集数信息
  String get episodeInfo {
    if (episodes.isEmpty) return '';
    return '${AppStrings.episodesCount}'.replaceAll('%d', '${episodes.length}');
  }

  /// 获取年份信息
  String get yearInfo {
    return year.isNotEmpty ? year : AppStrings.unknownYear;
  }

  /// 转换为VideoInfo
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id,
      source: source,
      title: title,
      sourceName: sourceName,
      year: year,
      cover: poster,
      index: 1, // 搜索结果默认从第1集开始
      totalEpisodes: episodes.length,
      playTime: 0, // 搜索结果默认未播放
      totalTime: 0, // 搜索结果默认未知总时长
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title, // 使用标题作为搜索标题
      doubanId: doubanId?.toString(), // 传递豆瓣ID，转换为字符串
    );
  }
}

/// WebSocket 搜索事件类型
enum SearchEventType {
  start,
  sourceResult,
  sourceError,
  complete,
}

/// WebSocket 搜索事件基类
abstract class SearchEvent {
  final SearchEventType type;
  final int timestamp;

  SearchEvent({
    required this.type,
    required this.timestamp,
  });

  factory SearchEvent.fromJson(Map<String, dynamic> json) {
    final typeString = json[AppConfig.jsonType] as String?;
    
    switch (typeString) {
      case AppConfig.searchEventStart:
        return SearchStartEvent.fromJson(json);
      case AppConfig.searchEventSourceResult:
        return SearchSourceResultEvent.fromJson(json);
      case AppConfig.searchEventSourceError:
        return SearchSourceErrorEvent.fromJson(json);
      case AppConfig.searchEventComplete:
        return SearchCompleteEvent.fromJson(json);
      default:
        throw Exception('${AppStrings.unknown}${AppStrings.unknownSearchEventType}: $typeString');
    }
  }
}

/// 搜索开始事件
class SearchStartEvent extends SearchEvent {
  final String query;
  final int totalSources;

  SearchStartEvent({
    required this.query,
    required this.totalSources,
    required super.timestamp,
  }) : super(
          type: SearchEventType.start,
        );

  factory SearchStartEvent.fromJson(Map<String, dynamic> json) {
    return SearchStartEvent(
      query: json[AppConfig.jsonQuery] ?? '',
      totalSources: json[AppConfig.jsonTotalSources] ?? 0,
      timestamp: json[AppConfig.jsonTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 搜索结果事件
class SearchSourceResultEvent extends SearchEvent {
  final String source;
  final String sourceName;
  final List<SearchResult> results;

  SearchSourceResultEvent({
    required this.source,
    required this.sourceName,
    required this.results,
    required super.timestamp,
  }) : super(
          type: SearchEventType.sourceResult,
        );

  factory SearchSourceResultEvent.fromJson(Map<String, dynamic> json) {
    final resultsData = json[AppConfig.jsonResults] as List<dynamic>? ?? json[AppConfig.jsonItems] as List<dynamic>? ?? [];
    final results = resultsData
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();

    return SearchSourceResultEvent(
      source: json[AppConfig.jsonSource] ?? '',
      sourceName: json[AppConfig.jsonSourceName] ?? '',
      results: results,
      timestamp: json[AppConfig.jsonTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 搜索错误事件
class SearchSourceErrorEvent extends SearchEvent {
  final String source;
  final String sourceName;
  final String error;

  SearchSourceErrorEvent({
    required this.source,
    required this.sourceName,
    required this.error,
    required super.timestamp,
  }) : super(
          type: SearchEventType.sourceError,
        );

  factory SearchSourceErrorEvent.fromJson(Map<String, dynamic> json) {
    return SearchSourceErrorEvent(
      source: json[AppConfig.jsonSource] ?? '',
      sourceName: json[AppConfig.jsonSourceName] ?? '',
      error: json[AppConfig.jsonError] ?? AppStrings.msgUnknownError,
      timestamp: json[AppConfig.jsonTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 搜索完成事件
class SearchCompleteEvent extends SearchEvent {
  final int totalResults;
  final int completedSources;

  SearchCompleteEvent({
    required this.totalResults,
    required this.completedSources,
    required super.timestamp,
  }) : super(
          type: SearchEventType.complete,
        );

  factory SearchCompleteEvent.fromJson(Map<String, dynamic> json) {
    return SearchCompleteEvent(
      totalResults: json[AppConfig.jsonTotalResults] ?? 0,
      completedSources: json[AppConfig.jsonCompletedSources] ?? 0,
      timestamp: json[AppConfig.jsonTimestamp] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
