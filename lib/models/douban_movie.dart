import 'video_info.dart';
import '../constants/app_config.dart';
import '../constants/app_regex.dart';
import '../constants/app_strings.dart';

/// 豆瓣推荐项目数据模型
class DoubanRecommendItem {
  final String id;
  final String title;
  final String poster;
  final String? rate;

  const DoubanRecommendItem({
    required this.id,
    required this.title,
    required this.poster,
    this.rate,
  });

  /// 从JSON创建DoubanRecommendItem实例
  factory DoubanRecommendItem.fromJson(Map<String, dynamic> json) {
    return DoubanRecommendItem(
      id: json[AppConfig.jsonId]?.toString() ?? '',
      title: json[AppConfig.jsonTitle]?.toString() ?? '',
      poster: json[AppConfig.jsonPoster]?.toString() ?? '',
      rate: json[AppConfig.jsonRate]?.toString(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonPoster: poster,
      AppConfig.jsonRate: rate,
    };
  }

  /// 转换为VideoInfo格式，用于VideoCard显示
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id,
      source: AppConfig.sourceDouban,
      title: title,
      sourceName: AppStrings.doubanSourceName,
      year: '', // 推荐项目没有年份信息
      cover: poster,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title,
      doubanId: id,
      rate: rate,
    );
  }
}

/// 豆瓣电影详情数据模型
class DoubanMovieDetails {
  final String id;
  final String title;
  final String poster;
  final String? rate;
  final String year;
  final String? summary;
  final List<String> genres;
  final List<String> directors;
  final List<String> screenwriters;
  final List<String> actors;
  final String? duration;
  final List<String> countries;
  final List<String> languages;
  final String? releaseDate;
  final String? originalTitle;
  final String? imdbId;
  final int? totalEpisodes;
  final List<DoubanRecommendItem> recommends;

  const DoubanMovieDetails({
    required this.id,
    required this.title,
    required this.poster,
    this.rate,
    required this.year,
    this.summary,
    this.genres = const [],
    this.directors = const [],
    this.screenwriters = const [],
    this.actors = const [],
    this.duration,
    this.countries = const [],
    this.languages = const [],
    this.releaseDate,
    this.originalTitle,
    this.imdbId,
    this.totalEpisodes,
    this.recommends = const [],
  });

  /// 从JSON创建DoubanMovieDetails实例
  factory DoubanMovieDetails.fromJson(Map<String, dynamic> json) {
    String? nonEmptyString(dynamic value) {
      final stringValue = value?.toString().trim();
      if (stringValue == null || stringValue.isEmpty || stringValue == AppConfig.jsonNullValue) {
        return null;
      }
      return stringValue;
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value
            .map(nonEmptyString)
            .whereType<String>()
            .toList();
      }
      final singleValue = nonEmptyString(value);
      return singleValue == null ? <String>[] : <String>[singleValue];
    }

    List<String> nameList(dynamic value) {
      if (value is! List) {
        return <String>[];
      }

      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return nonEmptyString(item[AppConfig.jsonName]);
            }
            return nonEmptyString(item);
          })
          .whereType<String>()
          .toList();
    }

    int? parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '');
    }

    // 处理poster字段
    String poster = '';
    if (json[AppConfig.jsonPoster] != null) {
      poster = json[AppConfig.jsonPoster]?.toString() ?? '';
    } else if (json[AppConfig.jsonCoverUrl] != null) {
      poster = json[AppConfig.jsonCoverUrl]?.toString() ?? '';
    } else if (json[AppConfig.jsonImages] != null) {
      final images = json[AppConfig.jsonImages] as Map<String, dynamic>?;
      poster = images?[AppConfig.jsonLarge]?.toString() ?? 
               images?[AppConfig.jsonMedium]?.toString() ?? 
               images?[AppConfig.jsonSmall]?.toString() ?? '';
    } else if (json[AppConfig.jsonPic] != null) {
      final pic = json[AppConfig.jsonPic] as Map<String, dynamic>?;
      poster = pic?[AppConfig.jsonLarge]?.toString() ??
               pic?[AppConfig.jsonNormal]?.toString() ??
               pic?[AppConfig.jsonMedium]?.toString() ??
               pic?[AppConfig.jsonSmall]?.toString() ?? '';
    }
    
    // 处理rating字段
    String? rate = nonEmptyString(json[AppConfig.jsonRate]);
    if (rate == null && json[AppConfig.jsonRating] != null) {
      final rating = json[AppConfig.jsonRating] as Map<String, dynamic>?;
      final value = rating?[AppConfig.jsonAverage] ?? rating?[AppConfig.jsonValue];
      if (value != null) {
        if (value is num) {
          rate = value.toStringAsFixed(1);
        } else {
          rate = value.toString();
        }
      }
    }
    if (rate == '0' || rate == '0.0') {
      rate = null;
    }
    
    // 处理年份
    String year = json[AppConfig.jsonYear]?.toString() ?? '';
    if (year.isEmpty && json[AppConfig.jsonPubdate] != null) {
      final pubdate = stringList(json[AppConfig.jsonPubdate]).join(' ');
      final yearMatch = RegExp(AppRegex.yearPattern).firstMatch(pubdate);
      year = yearMatch?.group(1) ?? '';
    }
    
    // 处理导演列表
    final directors = json[AppConfig.jsonDirectors] is List &&
            (json[AppConfig.jsonDirectors] as List).any((item) => item is Map)
        ? nameList(json[AppConfig.jsonDirectors])
        : stringList(json[AppConfig.jsonDirectors]);
    
    // 处理编剧列表
    final screenwriters = json[AppConfig.jsonScreenwriters] is List &&
            (json[AppConfig.jsonScreenwriters] as List).any((item) => item is Map)
        ? nameList(json[AppConfig.jsonScreenwriters])
        : stringList(json[AppConfig.jsonScreenwriters]);
    
    // 处理演员列表
    final actorsSource = json[AppConfig.jsonActors] ?? json[AppConfig.jsonCasts];
    final actors = actorsSource is List && actorsSource.any((item) => item is Map)
        ? nameList(actorsSource)
        : stringList(actorsSource);
    
    // 处理类型列表
    final genres = stringList(json[AppConfig.jsonGenres]);
    
    // 处理国家列表
    final countries = stringList(json[AppConfig.jsonCountries]);
    
    // 处理语言列表
    final languages = stringList(json[AppConfig.jsonLanguages]);
    
    // 处理推荐列表
    List<DoubanRecommendItem> recommends = [];
    if (json[AppConfig.jsonRecommends] != null) {
      final recommendsData = json[AppConfig.jsonRecommends] as List<dynamic>? ?? [];
      recommends = recommendsData.map((r) => DoubanRecommendItem.fromJson(r as Map<String, dynamic>)).toList();
    }
    
    // 处理总集数
    final totalEpisodes = parseInt(
      json[AppConfig.jsonEpisodeCount] ?? json[AppConfig.jsonTotalEpisodesCamel] ?? json[AppConfig.jsonTotalEpisodes],
    );
    final pubdates = stringList(json[AppConfig.jsonPubdate]);
    final durations = stringList(json[AppConfig.jsonDurations]);
    
    return DoubanMovieDetails(
      id: json[AppConfig.jsonId]?.toString() ?? '',
      title: json[AppConfig.jsonTitle]?.toString() ?? '',
      poster: poster,
      rate: rate,
      year: year,
      summary: nonEmptyString(json[AppConfig.jsonSummary] ?? json[AppConfig.jsonIntro]),
      genres: genres,
      directors: directors,
      screenwriters: screenwriters,
      actors: actors,
      duration: nonEmptyString(json[AppConfig.jsonDuration]) ??
          (durations.isNotEmpty ? durations.first : null),
      countries: countries,
      languages: languages,
      releaseDate: nonEmptyString(json[AppConfig.jsonReleaseDateCamel]) ??
          (pubdates.isNotEmpty ? pubdates.first : null),
      originalTitle: nonEmptyString(json[AppConfig.jsonOriginalTitleCamel] ?? json[AppConfig.jsonOriginalTitle]),
      imdbId: nonEmptyString(json[AppConfig.jsonImdbId] ?? json[AppConfig.jsonImdb]),
      totalEpisodes: totalEpisodes,
      recommends: recommends,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonPoster: poster,
      AppConfig.jsonRate: rate,
      AppConfig.jsonYear: year,
      AppConfig.jsonSummary: summary,
      AppConfig.jsonGenres: genres,
      AppConfig.jsonDirectors: directors,
      AppConfig.jsonScreenwriters: screenwriters,
      AppConfig.jsonActors: actors,
      AppConfig.jsonDuration: duration,
      AppConfig.jsonCountries: countries,
      AppConfig.jsonLanguages: languages,
      AppConfig.jsonReleaseDateCamel: releaseDate,
      AppConfig.jsonOriginalTitleCamel: originalTitle,
      AppConfig.jsonImdbId: imdbId,
      AppConfig.jsonTotalEpisodesCamel: totalEpisodes,
      AppConfig.jsonRecommends: recommends.map((r) => r.toJson()).toList(),
    };
  }
}

/// 豆瓣电影数据模型
class DoubanMovie {
  final String id;
  final String title;
  final String poster;
  final String? rate;
  final String year;

  const DoubanMovie({
    required this.id,
    required this.title,
    required this.poster,
    this.rate,
    required this.year,
  });

  /// 从JSON创建DoubanMovie实例
  factory DoubanMovie.fromJson(Map<String, dynamic> json) {
    // 处理poster字段，优先使用normal，其次large
    String poster = '';
    if (json[AppConfig.jsonPic] != null) {
      final pic = json[AppConfig.jsonPic] as Map<String, dynamic>?;
      poster = pic?[AppConfig.jsonNormal]?.toString() ?? 
               pic?[AppConfig.jsonLarge]?.toString() ?? '';
    }
    
    // 处理rating字段
    String? rate;
    if (json[AppConfig.jsonRating] != null) {
      final rating = json[AppConfig.jsonRating] as Map<String, dynamic>?;
      final value = rating?[AppConfig.jsonValue];
      if (value != null) {
        rate = (value as num).toStringAsFixed(1);
      }
    }
    
    // 处理年份，从card_subtitle中提取
    String year = '';
    if (json[AppConfig.jsonCardSubtitle] != null) {
      final cardSubtitle = json[AppConfig.jsonCardSubtitle]?.toString() ?? '';
      final yearMatch = RegExp(AppRegex.yearPattern).firstMatch(cardSubtitle);
      year = yearMatch?.group(1) ?? '';
    }
    
    return DoubanMovie(
      id: json[AppConfig.jsonId]?.toString() ?? '',
      title: json[AppConfig.jsonTitle]?.toString() ?? '',
      poster: poster,
      rate: rate,
      year: year,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonPoster: poster,
      AppConfig.jsonRate: rate,
      AppConfig.jsonYear: year,
    };
  }

  /// 转换为VideoInfo格式，用于VideoCard显示
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id,
      source: AppConfig.sourceDouban,
      title: title,
      sourceName: AppStrings.doubanSourceName,
      year: year,
      cover: poster,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title,
      doubanId: id,
      rate: rate,
    );
  }

}

/// 豆瓣API响应模型
class DoubanResponse {
  final List<DoubanMovie> items;

  const DoubanResponse({
    required this.items,
  });

  /// 从JSON创建DoubanResponse实例
  factory DoubanResponse.fromJson(Map<String, dynamic> json) {
    final itemsData = json[AppConfig.jsonItems] as List<dynamic>? ?? [];
    
    return DoubanResponse(
      items: itemsData.map((item) {
        return DoubanMovie.fromJson(item as Map<String, dynamic>);
      }).toList(),
    );
  }
}
